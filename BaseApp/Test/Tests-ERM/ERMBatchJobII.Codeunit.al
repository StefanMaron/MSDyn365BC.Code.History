codeunit 134919 "ERM Batch Job II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Budget]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        GLAccountNo: Code[20];
        Amount: Decimal;
        BudgetNameErrorMessage: Label 'You must specify a budget name to copy from.';
        DateIntervalErrorMessage: Label 'You must specify a date interval to copy from.';
        CopyToErrorMessage: Label 'You must specify a budget name to copy to.';
        BudgetName: Code[10];
        BudgetError: Label 'G/L Budget: %1 must not exist.', Comment = '%1=G/L Budget Name';

    [Test]
    [Scope('OnPrem')]
    procedure CopyFromGLBudgetError()
    var
        FromSource: Option "G/L Entry","G/L Budget Entry";
    begin
        // Check Error Message when Copy From Budget Field is not filled up while running Copy GL Budget Batch Job.

        // Setup.
        Initialize;

        // Exercise: Try to Run Copy GL Budget Batch job without Copy From GL Budget Name, GL Account No, Date Interval, Copy To GL Budget Name, Blank Rounding Method Code.
        asserterror RunCopyGLBudget(FromSource::"G/L Budget Entry", '', '', '', '', 1, '');  // Take 1 as Adjustment Factor.

        // Verify: Verify Error Message.
        Assert.ExpectedError(StrSubstNo(BudgetNameErrorMessage));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyFromDateIntervalError()
    var
        FromSource: Option "G/L Entry","G/L Budget Entry";
    begin
        // Check Error Message when Copy From Date Field is not filled up while running Copy GL Budget Batch Job.

        // Setup.
        Initialize;

        // Exercise: Try to Run Copy GL Budget Batch job without GL Account No, Date Interval, Copy To GL Budget Name and Blank Rounding Method Code, take 1 as Adjustment Factor.
        asserterror RunCopyGLBudget(FromSource::"G/L Entry", '', '', '', '', 1, '');

        // Verify: Verify Error Message.
        Assert.ExpectedError(StrSubstNo(DateIntervalErrorMessage));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyToGLBudgetError()
    var
        FromSource: Option "G/L Entry","G/L Budget Entry";
    begin
        // Check Error Message when Copy to Budget Field is not filled up while running Copy GL Budget Batch Job.

        // Setup.
        Initialize;

        // Exercise: Try to Run Copy GL Budget Batch job without Copy From GL Budget Name, GL Account No, Copy To GL Budget Name and Blank Rounding Method Code.
        asserterror RunCopyGLBudget(FromSource::"G/L Entry", '', '', Format(WorkDate), '', 1, '');  // Take 1 as Adjustment Factor.

        // Verify: Verify Error Message.
        Assert.ExpectedError(StrSubstNo(CopyToErrorMessage));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetCreation()
    var
        GLBudgetName: Record "G/L Budget Name";
        FromSource: Option "G/L Entry","G/L Budget Entry";
        NewBudgetName: Code[10];
    begin
        // Check that new GL Budget created after confirming message asked to create GL Budget while running Copy GL Budget.

        // Setup: Take a Random Name for Copy To GL Budget Name.
        Initialize;
        NewBudgetName := Format(LibraryRandom.RandInt(100));

        // Exercise: Run Copy GL Budget Using blank for Copy From GL Budget, Rounding Method and 1 for Adjustment Factor.
        RunCopyGLBudget(FromSource::"G/L Entry", '', GLAccountNo, Format(WorkDate), NewBudgetName, 1, '');

        // Verify: Verify that new GL Budget Exists.
        GLBudgetName.Get(NewBudgetName);

        // Tear Down: Delete the GL Budget created earlier.
        GLBudgetName.Delete(true);
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetCreationDeclined()
    var
        GLBudgetName: Record "G/L Budget Name";
        FromSource: Option "G/L Entry","G/L Budget Entry";
        NewBudgetName: Code[10];
    begin
        // Check that GL Budget does not exist when creation confirmation message for GL Budget declined.

        // Setup: Create and Post General Journal Line for a GL Account with random Amount.
        Initialize;
        NewBudgetName := Format(LibraryRandom.RandInt(100));  // Taking a Random Name for New Budget to be created.
        GLBudgetName.FindFirst;

        // Exercise: Run Copy GL Budget using blank for Rounding Method, GL Account No. and 1 for Adjustment Factor.
        RunCopyGLBudget(FromSource::"G/L Budget Entry", GLBudgetName.Name, '', Format(WorkDate), NewBudgetName, 1, '');

        // Verify: Verify that new GL Budget must not exists after declining to create a new Budget.
        GLBudgetName.SetRange(Name, NewBudgetName);
        Assert.IsFalse(GLBudgetName.FindFirst, StrSubstNo(BudgetError, NewBudgetName));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,BudgetPageHandler')]
    [Scope('OnPrem')]
    procedure CopyGLBudgetSourceGLEntry()
    var
        FromSource: Option "G/L Entry","G/L Budget Entry";
    begin
        // Check correct Amount copied to new GL Budget when Copy From Source is GL Entry.

        // Setup: Create and Post General Journal Line for a GL Account with random Amount.
        Initialize;
        GLAccountNo := LibraryERM.CreateGLAccountNo;  // Assign GL Account No. to global variable.
        Amount := LibraryRandom.RandDec(100, 2);  // Assign Random Amount to global variable.
        CreateAndPostGenJournalLine(GLAccountNo, Amount);
        CopyGLBudgetFromDifferentSources(FromSource::"G/L Entry", '', 1, '');  // Passing blanks for Copy From GL Budget Name and Rounding Method, 1 for Adjustment Factor.
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,BudgetPageHandler')]
    [Scope('OnPrem')]
    procedure CopyGLBudgetSourceGLBudgetEntry()
    var
        GLBudgetName: Record "G/L Budget Name";
        FromSource: Option "G/L Entry","G/L Budget Entry";
    begin
        // Check correct Amount copied on new GL Budget when Copy From Source is GL Budget Entry.

        // Setup: Create GL Budget Entry for a GL Account with random Amount.
        Initialize;
        GLBudgetName.FindFirst;
        GLAccountNo := LibraryERM.CreateGLAccountNo;  // Assign GL Account No. to  global variable.
        Amount := LibraryRandom.RandDec(100, 2);  // Assign Random Amount to global variable.
        CreateGLBudgetEntry(GLBudgetName.Name, GLAccountNo, Amount);
        CopyGLBudgetFromDifferentSources(FromSource::"G/L Budget Entry", GLBudgetName.Name, 1, '');  // Passing blank for Rounding Method, 1 for Adjustment Factor.
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,BudgetPageHandler')]
    [Scope('OnPrem')]
    procedure GLEntryWithRoundingMethod()
    var
        FromSource: Option "G/L Entry","G/L Budget Entry";
    begin
        // Check correct Amount copied on new GL Budget while Copy From Source is GL Entry and a Rounding Method used.

        // Setup: Create and Post General Journal Line with random Amount.
        Initialize;
        GLAccountNo := LibraryERM.CreateGLAccountNo;  // Assign GL Account No. to global variable.
        Amount := LibraryRandom.RandDec(100, 2);  // Assign Random Amount to global variable.
        CreateAndPostGenJournalLine(GLAccountNo, Amount);
        CopyGLBudgetFromDifferentSources(FromSource::"G/L Entry", '', 1, CalculateAmountUsingRoundingMethod(Amount));  // Passing blank for Copy From GL Budget, 1 for Adjustment Factor.
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,BudgetPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetEntryWithRoundingMethod()
    var
        GLBudgetName: Record "G/L Budget Name";
        FromSource: Option "G/L Entry","G/L Budget Entry";
    begin
        // Check correct Amount copied on new GL Budget while Copy From Source is GL Budget Entry and a Rounding Method Used.

        // Setup: Create GL Budget Entry for a GL Account with random Amount.
        Initialize;
        GLBudgetName.FindFirst;
        GLAccountNo := LibraryERM.CreateGLAccountNo;  // Assign GL Account No. to global variable.
        Amount := LibraryRandom.RandDec(100, 2);  // Assign Random Amount to global variable.
        CreateGLBudgetEntry(GLBudgetName.Name, GLAccountNo, Amount);
        CopyGLBudgetFromDifferentSources(FromSource::"G/L Budget Entry", GLBudgetName.Name, 1, CalculateAmountUsingRoundingMethod(Amount));  // Passing 1 for Adjustment Factor.
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,BudgetPageHandler')]
    [Scope('OnPrem')]
    procedure GLEntryWithAdjustmentFactor()
    var
        FromSource: Option "G/L Entry","G/L Budget Entry";
        AdjustmentFactor: Decimal;
    begin
        // Check correct Amount copied on new GL Budget while Copy From Source is GL Entry and random Adjustment Factor used.

        // Setup: Create and Post General Journal Line with random Amount, take random Adjustment Factor.
        Initialize;
        GLAccountNo := LibraryERM.CreateGLAccountNo;  // Assign GL Account No. to global variable.
        Amount := LibraryRandom.RandDec(100, 2);  // Assign Random Amount to global variable.
        AdjustmentFactor := LibraryRandom.RandDec(10, 2);
        CreateAndPostGenJournalLine(GLAccountNo, Amount);
        Amount := AdjustmentFactor * Amount;  // Calculate Expected Amount after using adjustment factor and assign it to global variable.
        CopyGLBudgetFromDifferentSources(FromSource::"G/L Entry", '', AdjustmentFactor, '');  // Passing blank for Copy From Budget and Rounding Method.
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler,BudgetPageHandler')]
    [Scope('OnPrem')]
    procedure GLBudgetEntryWithAdjustmentFactor()
    var
        GLBudgetName: Record "G/L Budget Name";
        AdjustmentFactor: Decimal;
        FromSource: Option "G/L Entry","G/L Budget Entry";
    begin
        // Check correct Amount copied on new GL Budget while Copy From Source is GL Budget Entry and random Adjustment Factor used.

        // Setup: Create GL Budget Entry for a GL Account with random Amount, take random Adjustment Factor.
        Initialize;
        GLBudgetName.FindFirst;
        GLAccountNo := LibraryERM.CreateGLAccountNo;  // Assign GL Account No. to global variable.
        Amount := LibraryRandom.RandDec(100, 2);  // Assign Random Amount to global variable.
        AdjustmentFactor := LibraryRandom.RandDec(10, 2);
        CreateGLBudgetEntry(GLBudgetName.Name, GLAccountNo, Amount);
        Amount := AdjustmentFactor * Amount;  // Calculate Expected Amount after using adjustment factor and assign it to global variable.
        CopyGLBudgetFromDifferentSources(FromSource::"G/L Budget Entry", GLBudgetName.Name, AdjustmentFactor, '');  // Passing blank for Rounding Method.
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Batch Job II");
        ClearGlobalVariables;
    end;

    local procedure CalculateAmountUsingRoundingMethod(OldAmount: Decimal): Code[10]
    var
        RoundingMethod: Record "Rounding Method";
    begin
        RoundingMethod.FindFirst;
        Amount := Round(OldAmount, RoundingMethod.Precision, InvoiceRoundingDirection(RoundingMethod.Type));  // Update the Amount as per Rounding Method and Assign it to global variable.
        exit(RoundingMethod.Code);
    end;

    local procedure ClearGlobalVariables()
    begin
        Amount := 0;
        Clear(GLAccountNo);
        Clear(BudgetName);
    end;

    local procedure CopyGLBudgetFromDifferentSources(FromSource: Option; FromGLBudgetName: Code[10]; AdjustmentFactor: Decimal; RoundingMethodCode: Code[10])
    var
        GLBudgetName: Record "G/L Budget Name";
    begin
        // Create GL Budget to copy an existing GL Budget.
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        BudgetName := GLBudgetName.Name;  // Assign GL Budget Name to global variable.

        // Exercise.
        RunCopyGLBudget(FromSource, FromGLBudgetName, GLAccountNo, Format(WorkDate), BudgetName, AdjustmentFactor, RoundingMethodCode);

        // Verify: Verify Amount on GL Budget Page.
        OpenGLBudgetPage;

        // Tear Down: Delete earlier created GL Budget.
        GLBudgetName.Get(BudgetName);
        GLBudgetName.Delete(true);
    end;

    local procedure CreateAndPostGenJournalLine(AccountNo: Code[20]; LineAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", AccountNo, LineAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGLBudgetEntry(GLBudgetName: Code[10]; AccountNo: Code[20]; Amount2: Decimal)
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, WorkDate, AccountNo, GLBudgetName);
        GLBudgetEntry.Validate(Amount, Amount2);  // Taking Variable name Amount2 due to global variable.
        GLBudgetEntry.Modify(true);
    end;

    local procedure InvoiceRoundingDirection(Type: Option Nearest,Up,Down): Text[1]
    begin
        // Taken the formula to return Rounding Type from Currency Table .
        case Type of
            Type::Nearest:
                exit('=');
            Type::Up:
                exit('>');
            Type::Down:
                exit('<');
        end;
    end;

    local procedure OpenGLBudgetPage()
    var
        GLBudgetNamesPage: TestPage "G/L Budget Names";
    begin
        GLBudgetNamesPage.OpenEdit;
        GLBudgetNamesPage.FILTER.SetFilter(Name, BudgetName);
        GLBudgetNamesPage.EditBudget.Invoke;
    end;

    local procedure RunCopyGLBudget(FromSource: Option; FromGLBudgetName: Code[10]; FromGLAccount: Code[20]; DateInterval: Text[30]; ToGlBudgetName: Code[10]; AdjustmentFactor: Decimal; RoundingMethodCode: Code[10])
    var
        CopyGLBudget: Report "Copy G/L Budget";
        ToDateCompression: Option "None",Day,Week,Month,Quarter,Year,Period;
        FromClosingEntryFilter: Option Include,Exclude;
        DateChangeFormula: DateFormula;
    begin
        Clear(CopyGLBudget);
        Evaluate(DateChangeFormula, '');  // Evaluating blank value in Date Formula variable.
        CopyGLBudget.InitializeRequest(
          FromSource, FromGLBudgetName, FromGLAccount, DateInterval, FromClosingEntryFilter::Include, '', ToGlBudgetName, '', AdjustmentFactor,
          RoundingMethodCode, DateChangeFormula, ToDateCompression::None);
        CopyGLBudget.UseRequestPage(false);
        CopyGLBudget.Run;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BudgetPageHandler(var Budget: TestPage Budget)
    begin
        Budget.PeriodType.SetValue('Day');
        Budget.DateFilter.SetValue(WorkDate);
        Budget.IncomeBalGLAccFilter.SetValue(0);
        Budget.GLAccCategory.SetValue(0);
        Budget.GLAccFilter.SetValue(GLAccountNo);
        Budget.MatrixForm.TotalBudgetedAmount.AssertEquals(Amount);
        Budget.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // For handle message
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure NoConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

