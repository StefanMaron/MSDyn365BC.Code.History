codeunit 134554 "ERM Cash Flow - Posting"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cash Flow]
    end;

    var
        LibraryCashFlowHelper: Codeunit "Library - Cash Flow Helper";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryCF: Codeunit "Library - Cash Flow";
        LibraryERM: Codeunit "Library - ERM";
        RecordNotDeletedTxt: Label 'Records in table %1 was not deleted.';
        BeforeAndAfterCounterTxt: Label 'Counters dosn''t match: before: %1 and after: %2.';
        WrongAmountaTxt: Label 'Amounts before and after posting dosn''t match.';

    [Test]
    [Scope('OnPrem')]
    procedure Test_CFJnlPostBatch()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        CounterBefore: Integer;
        CounterAfter: Integer;
        AmountBefore: Decimal;
        AmountAfter: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        UpdateCashFlowSetup; // NAVCZ
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);

        with CashFlowForecast do begin
            ConsiderAllSources(ConsiderSource);
            LibraryCashFlowHelper.FillJournal(ConsiderSource, "No.", false);

            CFWorksheetLine.SetCurrentKey("Cash Flow Forecast No.");
            CFWorksheetLine.SetRange("Cash Flow Forecast No.", "No.");
            CounterBefore := CFWorksheetLine.Count;
            CFWorksheetLine.CalcSums("Amount (LCY)");
            AmountBefore := CFWorksheetLine."Amount (LCY)";

            PostBatch(CFWorksheetLine);

            // Validate results
            CFForecastEntry.SetCurrentKey("Cash Flow Forecast No.");
            CFForecastEntry.SetRange("Cash Flow Forecast No.", "No.");
            CounterAfter := CFForecastEntry.Count;
            CFForecastEntry.CalcSums("Amount (LCY)");
            AmountAfter := CFForecastEntry."Amount (LCY)";

            Assert.AreEqual(CounterBefore, CounterAfter, StrSubstNo(BeforeAndAfterCounterTxt, CounterBefore, CounterAfter));
            Assert.AreEqual(AmountBefore, AmountAfter, WrongAmountaTxt);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Test_CF_OnDelete()
    var
        CFAccountComment: Record "Cash Flow Account Comment";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        ConsiderSource: array[16] of Boolean;
    begin
        UpdateCashFlowSetup; // NAVCZ
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);

        with CashFlowForecast do begin
            CFAccountComment."Table Name" := CFAccountComment."Table Name"::"Cash Flow Forecast";
            CFAccountComment."No." := "No.";
            CFAccountComment."Line No." := 1;
            CFAccountComment.Comment := "No.";
            CFAccountComment.Insert;

            ConsiderAllSources(ConsiderSource);
            LibraryCashFlowHelper.FillJournal(ConsiderSource, "No.", false);

            CFWorksheetLine.SetCurrentKey("Cash Flow Forecast No.");
            CFWorksheetLine.SetRange("Cash Flow Forecast No.", "No.");
            PostBatch(CFWorksheetLine);

            Delete(true);

            // Validate results
            CFAccountComment.Reset;
            CFAccountComment.SetRange("Table Name", CFAccountComment."Table Name"::"Cash Flow Forecast");
            CFAccountComment.SetRange("No.", "No.");
            Assert.AreEqual(0, CFAccountComment.Count, StrSubstNo(RecordNotDeletedTxt, CFAccountComment.TableCaption));

            CFForecastEntry.SetCurrentKey("Cash Flow Forecast No.");
            CFForecastEntry.SetRange("Cash Flow Forecast No.", "No.");
            Assert.AreEqual(0, CFForecastEntry.Count, StrSubstNo(RecordNotDeletedTxt, CFForecastEntry.TableCaption));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostingWithEmptyBudgetName()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        // Setup
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CreateGLBudgetCFWorksheetLine(GLBudgetEntry, CFWorksheetLine, CashFlowForecast, LibraryRandom.RandDec(100, 2));

        // Exercise
        CFWorksheetLine.Validate("G/L Budget Name", '');
        CFWorksheetLine.Modify;

        // Verify
        asserterror LibraryCF.PostJournalLines(CFWorksheetLine);
        Assert.ExpectedError(StrSubstNo('%1 must have a value in', CFWorksheetLine."G/L Budget Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostingBudgetNameForNotBudgetSourceType()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GLBudgetEntry: Record "G/L Budget Entry";
        CFForecastEntry: Record "Cash Flow Forecast Entry";
    begin
        // Setup
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CreateGLBudgetCFWorksheetLine(GLBudgetEntry, CFWorksheetLine, CashFlowForecast, LibraryRandom.RandDec(100, 2));

        // Exercise
        CFWorksheetLine.Validate("Source Type", LibraryRandom.RandIntInRange(1, CFWorksheetLine."Source Type"::"G/L Budget" - 1));
        CFWorksheetLine.Modify;
        LibraryCF.PostJournalLines(CFWorksheetLine);

        // Verify
        CFForecastEntry.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        CFForecastEntry.FindFirst;
        CFForecastEntry.TestField("G/L Budget Name", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateGLBudgetEntries()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        GLBudgetEntry: Record "G/L Budget Entry";
        ExpectedAmount: Decimal;
    begin
        // Setup
        LibraryCashFlowHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        ExpectedAmount := LibraryRandom.RandDec(100, 2);
        CreateGLBudgetCFWorksheetLine(GLBudgetEntry, CFWorksheetLine, CashFlowForecast, -ExpectedAmount);

        // Exercise
        LibraryCF.PostJournalLines(CFWorksheetLine);

        // Verify
        CFForecastEntry.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        CFForecastEntry.FindFirst;
        CFForecastEntry.TestField("Source Type", CFForecastEntry."Source Type"::"G/L Budget");
        CFForecastEntry.TestField("G/L Budget Name", GLBudgetEntry."Budget Name");
        LibraryCashFlowHelper.VerifyExpectedCFAmount(-ExpectedAmount, CFForecastEntry."Amount (LCY)");
    end;

    local procedure CreateGLBudgetCFWorksheetLine(var GLBudgetEntry: Record "G/L Budget Entry"; var CFWorksheetLine: Record "Cash Flow Worksheet Line"; var CashFlowForecast: Record "Cash Flow Forecast"; CashFlowAmount: Decimal)
    var
        CFAccount: Record "Cash Flow Account";
        GLAccount: Record "G/L Account";
        GLBudgetName: Record "G/L Budget Name";
    begin
        LibraryCashFlowHelper.FindCFBudgetAccount(CFAccount);
        LibraryCashFlowHelper.FindFirstGLAccFromCFAcc(GLAccount, CFAccount);
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, CashFlowForecast."G/L Budget From", GLAccount."No.", GLBudgetName.Name);
        GLBudgetEntry.Validate(Amount, LibraryRandom.RandDec(100, 2));
        GLBudgetEntry.Modify(true);

        with CFWorksheetLine do begin
            Init;
            "Cash Flow Date" := WorkDate;
            "Document No." := Format(LibraryRandom.RandInt(50));
            "Cash Flow Forecast No." := CashFlowForecast."No.";
            Description := "Document No.";
            "Cash Flow Account No." := CFAccount."No.";
            "Amount (LCY)" := CashFlowAmount;
            "Source Type" := "Source Type"::"G/L Budget";
            "Source No." := GLAccount."No.";
            "G/L Budget Name" := GLBudgetName.Name;
            Insert(true);
        end;
    end;

    local procedure ConsiderAllSources(var ConsiderSource: array[16] of Boolean)
    var
        SourceType: Integer;
    begin
        for SourceType := 1 to ArrayLen(ConsiderSource) do
            ConsiderSource[SourceType] := true;
    end;

    local procedure PostBatch(var CFWorksheetLine: Record "Cash Flow Worksheet Line")
    begin
        CFWorksheetLine.FindFirst;
        CODEUNIT.Run(CODEUNIT::"Cash Flow Wksh.-Register Batch", CFWorksheetLine);
    end;

    local procedure UpdateCashFlowSetup()
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        // NAVCZ
        CashFlowSetup.Get;
        CashFlowSetup."S. Adv. Letter CF Account No." := CashFlowSetup."Receivables CF Account No.";
        CashFlowSetup."P. Adv. Letter CF Account No." := CashFlowSetup."Payables CF Account No.";
        CashFlowSetup.Modify;
    end;
}

