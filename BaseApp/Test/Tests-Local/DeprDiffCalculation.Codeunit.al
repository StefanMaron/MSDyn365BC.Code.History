codeunit 144020 "Depr. Diff. Calculation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Fixed Asset] [Depreciation]
        isInitialized := false;
    end;

    var
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        isInitialized: Boolean;
        PleaseEnterPostingDateTxt: Label 'Please enter the Posting Date.';
        PleaseEnterDocumentNoTxt: Label 'Please enter the Document No.';
        PleaseEnterStartingDateTxt: Label 'Please enter the Starting Date for Depreciation Calculation.';
        PleaseEnterEndingDateTxt: Label 'Please enter the Ending Date for Depreciation Calculation.';
        EndingDateAfterStartingDateTxt: Label 'Ending Date must not be before Starting Date.';
        PleaseEnterBook1AndBook2Txt: Label 'Please specify Depreciation Book Code 1 and Depreciation Book Code 2.';
        SpecifyDeprDiffAccTxt: Label 'You must specify Depr. Difference Acc. in FA posting Group';
        SpecifyDeprDiffBalAccTxt: Label 'You must specify Depr. Difference Bal. Acc. in FA posting Group';
        DeprDiffPostedTxt: Label 'The Depreciation Difference was successfully posted.';
        PostingDeprDiffTxt: Label 'Do you want to post the Depreciation Difference ?';
        Book1InGLTxt: Label 'The Depreciation Book Code 1 must be integrated with G/L.';
        Book2NotInGLTxt: Label 'The Depreciation Book Code 2 must not be integrated with G/L.';
        NoDeprDiffPostedTxt: Label 'There is no Depreciation Difference posted for the specified period.';
        ZeroDifferenceLineErr: Label '''%1'' report contains lines with 0 in difference amount';
        HandledMessage: Text;
        DifferenceAmtErr: Label 'Current row does not have ''DifferenceAmt'' value greater than zero. Value  = <%1>.', Comment = '%1 is the name of the DataSet field, and %2 is the value of that field.';
        CompletionStatsTok: Label 'The depreciation has been calculated.';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Depr. Diff. Calculation");
        LibraryVariableStorage.Clear;
        Clear(LibraryReportValidation);
        Clear(HandledMessage);
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Depr. Diff. Calculation");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Depr. Diff. Calculation");
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcAndPostDeprDifferenceReportWithZeroDifference()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        StartingDate: Date;
        PostingDate: Date;
        FixedAssetNo1: Code[20];
        FixedAssetNo2: Code[20];
    begin
        // Setup
        Initialize;
        StartingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate);
        PostingDate := CalcDate('<3M-1D>', StartingDate);
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);

        // Excercise
        with FADepreciationBook do begin
            FixedAssetNo1 :=
              CreateFAAndPostDepreciation(
                4000, StartingDate, PostingDate, DepreciationBookCodeSUMU, DepreciationBookCodeTax,
                "Depreciation Method"::"Declining-Balance 1", '', 25, false, false);
            FixedAssetNo2 :=
              CreateFAAndPostDepreciation(
                6000, StartingDate, PostingDate, DepreciationBookCodeSUMU, DepreciationBookCodeTax,
                "Depreciation Method"::"Straight-Line", '<3Y-1D>', 0, false, false);
        end;

        RunCalcAndPostDeprDifferenceReportWithEnqueue(
          DepreciationBookCodeSUMU, DepreciationBookCodeTax, StartingDate, PostingDate, PostingDate,
          CopyStr(Format(CreateGuid), 1, 20), false, false, StrSubstNo('%1..%2', FixedAssetNo1, FixedAssetNo2));

        // Verify
        VerifyCalcAndPostDeprDifferenceReportWithZeroDifference;
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcAndPostDeprDifferenceReportWithEmptyLines()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        StartingDate: Date;
        PostingDate: Date;
        FixedAssetNo1: Code[20];
    begin
        // Setup
        Initialize;
        StartingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate);
        PostingDate := CalcDate('<3M-1D>', StartingDate);
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);

        // Excercise
        FixedAssetNo1 := CreateFAAndPostDepreciation(
            6000, StartingDate, PostingDate, DepreciationBookCodeSUMU, DepreciationBookCodeTax,
            FADepreciationBook."Depreciation Method"::"Straight-Line", '<3Y-1D>', 0, false, false);

        RunCalcAndPostDeprDifferenceReportWithEnqueue(
          DepreciationBookCodeSUMU, DepreciationBookCodeTax, StartingDate, PostingDate, PostingDate,
          CopyStr(Format(CreateGuid), 1, 20), true, false, FixedAssetNo1);

        // Verify
        VerifyCalcAndPostDeprDifferenceReportWithEmptyLines;
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH,PostingDeprDiffCFH,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcAndPostDeprDifferenceReportWithDifference()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        StartingDate: Date;
        PostingDate: Date;
        FixedAssetNo1: Code[20];
        FixedAssetNo2: Code[20];
        ExpectedMessage: Text;
    begin
        // Setup
        Initialize;
        StartingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate);
        PostingDate := CalcDate('<3M-1D>', StartingDate);
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);

        // Excercise
        with FADepreciationBook do begin
            FixedAssetNo1 :=
              CreateFAAndPostDepreciation(
                4000, StartingDate, PostingDate, DepreciationBookCodeSUMU, DepreciationBookCodeTax,
                "Depreciation Method"::"Declining-Balance 1", '', 25, false, false);
            FixedAssetNo2 :=
              CreateFAAndPostDepreciation(
                6000, StartingDate, PostingDate, DepreciationBookCodeSUMU, DepreciationBookCodeTax,
                "Depreciation Method"::"Straight-Line", '<3Y-1D>', 0, false, false);
        end;

        RunCalcAndPostDeprDifferenceReportWithEnqueue(
          DepreciationBookCodeSUMU, DepreciationBookCodeTax, StartingDate, PostingDate, PostingDate,
          CopyStr(Format(CreateGuid), 1, 20), false, true, StrSubstNo('%1..%2', FixedAssetNo1, FixedAssetNo2));

        // Verify
        ExpectedMessage := DeprDiffPostedTxt;
        Assert.AreEqual(ExpectedMessage, HandledMessage, 'DeprDiffPostedTxt must be equal to Report13402.Text13408');
        VerifyCalcAndPostDeprDifferenceReportWithDifference;
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure SpecifyDeprDiffAcc()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        StartingDate: Date;
        PostingDate: Date;
        FixedAssetNo1: Code[20];
    begin
        // Setup
        Initialize;
        StartingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate);
        PostingDate := CalcDate('<3M-1D>', StartingDate);
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);

        // Excercise
        FixedAssetNo1 := CreateFAAndPostDepreciation(
            4000, StartingDate, PostingDate, DepreciationBookCodeSUMU, DepreciationBookCodeTax,
            FADepreciationBook."Depreciation Method"::"Declining-Balance 1", '', 25, true, false);

        asserterror RunCalcAndPostDeprDifferenceReportWithEnqueue(
            DepreciationBookCodeSUMU, DepreciationBookCodeTax, StartingDate, PostingDate, PostingDate, '', false, false, Format(FixedAssetNo1));

        // Verify
        Assert.ExpectedError(SpecifyDeprDiffAccTxt);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure SpecifyDeprDiffBalAcc()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        StartingDate: Date;
        PostingDate: Date;
        FixedAssetNo1: Code[20];
    begin
        // Setup
        Initialize;
        StartingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate);
        PostingDate := CalcDate('<3M-1D>', StartingDate);
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);

        // Excercise
        FixedAssetNo1 := CreateFAAndPostDepreciation(
            4000, StartingDate, PostingDate, DepreciationBookCodeSUMU, DepreciationBookCodeTax,
            FADepreciationBook."Depreciation Method"::"Declining-Balance 1", '', 25, false, true);

        asserterror RunCalcAndPostDeprDifferenceReportWithEnqueue(
            DepreciationBookCodeSUMU, DepreciationBookCodeTax, StartingDate, PostingDate, PostingDate, '', false, false, Format(FixedAssetNo1));

        // Verify
        Assert.ExpectedError(SpecifyDeprDiffBalAccTxt);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH')]
    [Scope('OnPrem')]
    procedure PleaseEnterPostingDate()
    var
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        PostingDate: Date;
        PostDepreciationDifference: Boolean;
    begin
        // Setup
        Initialize;
        PostingDate := 0D;
        PostDepreciationDifference := true;
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);
        Commit();

        // Excercise
        asserterror RunCalcAndPostDeprDifferenceReportWithEnqueue(
            DepreciationBookCodeSUMU, DepreciationBookCodeTax, WorkDate, WorkDate, PostingDate, '', false, PostDepreciationDifference, '');

        // Verify
        Assert.ExpectedError(PleaseEnterPostingDateTxt);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH')]
    [Scope('OnPrem')]
    procedure PleaseEnterDocumentNo()
    var
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        DocumentNo: Code[20];
        PostDepreciationDifference: Boolean;
    begin
        // Setup
        Initialize;
        DocumentNo := '';
        PostDepreciationDifference := true;
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);
        Commit();

        // Excercise
        asserterror RunCalcAndPostDeprDifferenceReportWithEnqueue(
            DepreciationBookCodeSUMU, DepreciationBookCodeTax, WorkDate, WorkDate, WorkDate, DocumentNo, false, PostDepreciationDifference, '');

        // Verify
        Assert.ExpectedError(PleaseEnterDocumentNoTxt);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH')]
    [Scope('OnPrem')]
    procedure PleaseEnterStartingDate()
    var
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        StartingDate: Date;
    begin
        // Setup
        Initialize;
        StartingDate := 0D;
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);
        Commit();

        // Excercise
        asserterror RunCalcAndPostDeprDifferenceReportWithEnqueue(
            DepreciationBookCodeSUMU, DepreciationBookCodeTax, StartingDate, WorkDate, WorkDate, '', false, false, '');

        // Verify
        Assert.ExpectedError(PleaseEnterStartingDateTxt);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH')]
    [Scope('OnPrem')]
    procedure PleaseEnterEndingDate()
    var
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        EndingDate: Date;
    begin
        // Setup
        Initialize;
        EndingDate := 0D;
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);
        Commit();

        // Excercise
        asserterror RunCalcAndPostDeprDifferenceReportWithEnqueue(
            DepreciationBookCodeSUMU, DepreciationBookCodeTax, WorkDate, EndingDate, WorkDate, '', false, false, '');

        // Verify
        Assert.ExpectedError(PleaseEnterEndingDateTxt);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH')]
    [Scope('OnPrem')]
    procedure EndingDateAfterStartingDate()
    var
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        EndingDate: Date;
        StartingDate: Date;
    begin
        // Setup
        Initialize;
        StartingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate);
        EndingDate := CalcDate('<-1D>', StartingDate);
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);
        Commit();

        // Excercise
        asserterror RunCalcAndPostDeprDifferenceReportWithEnqueue(
            DepreciationBookCodeSUMU, DepreciationBookCodeTax, WorkDate, EndingDate, WorkDate, '', false, false, '');

        // Verify
        Assert.ExpectedError(EndingDateAfterStartingDateTxt);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH')]
    [Scope('OnPrem')]
    procedure PleaseEnterBook1AndBook2()
    var
        EmptyBookCode: Code[10];
    begin
        // Setup
        Initialize;
        EmptyBookCode := '';

        // Excercise
        asserterror RunCalcAndPostDeprDifferenceReportWithEnqueue(
            EmptyBookCode, EmptyBookCode, WorkDate, WorkDate, WorkDate, '', false, false, '');

        // Verify
        Assert.ExpectedError(PleaseEnterBook1AndBook2Txt);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH')]
    [Scope('OnPrem')]
    procedure Book1InGL()
    var
        BookInGL: Code[10];
    begin
        // Setup
        Initialize;
        BookInGL := CreateDepreciationBook(0, false);
        Commit();

        // Excercise
        asserterror RunCalcAndPostDeprDifferenceReportWithEnqueue(
            BookInGL, BookInGL, WorkDate, WorkDate, WorkDate, '', false, false, '');

        // Verify
        Assert.ExpectedError(Book1InGLTxt);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH')]
    [Scope('OnPrem')]
    procedure Book2NotInGL()
    var
        BookNotInGL: Code[10];
    begin
        // Setup
        Initialize;
        BookNotInGL := CreateDepreciationBook(0, true);
        Commit();

        // Excercise
        asserterror RunCalcAndPostDeprDifferenceReportWithEnqueue(BookNotInGL, BookNotInGL, WorkDate, WorkDate, WorkDate, '', false, false, '');

        // Verify
        Assert.ExpectedError(Book2NotInGLTxt);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH,PostingDeprDiffCFH,MessageHandler')]
    [Scope('OnPrem')]
    procedure NoDeprDiffPosted()
    var
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        PostingDate: Date;
        ExpectedMessage: Text;
    begin
        // Setup
        Initialize;
        PostingDate := DMY2Date(1, 1, 1900);
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);
        Commit();

        // Excercise
        RunCalcAndPostDeprDifferenceReportWithEnqueue(
          DepreciationBookCodeSUMU, DepreciationBookCodeTax, PostingDate, PostingDate, PostingDate,
          CopyStr(Format(CreateGuid), 1, 20), false, true, '');

        // Verify
        ExpectedMessage := NoDeprDiffPostedTxt;
        Assert.AreEqual(ExpectedMessage, HandledMessage, 'NoDeprDiffPostedTxt must be equal to Report13402.Text13412');
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH,PostingDeprDiffCFH,MessageHandlerWithEnqueue')]
    [Scope('OnPrem')]
    procedure CalcAndPostDeprDiffWithOneBookZeroDepr()
    var
        FixedAsset: Record "Fixed Asset";
        FALedgerEntry: Record "FA Ledger Entry";
        FADepreciationBook: Record "FA Depreciation Book";
        DeprBookCode: array[2] of Code[10];
    begin
        // [SCENARIO 311958] Calc And Post Deprectiation Difference repost posts difference when one of the values is zero, but the other is not
        Initialize;

        // [GIVEN] Depreciation book "B1" integrated to ledger
        DeprBookCode[1] := CreateDepreciationBook(0, true);

        // [GIVEN] Depreciation book "B2"
        DeprBookCode[2] := CreateDepreciationBook(0, false);

        // [GIVEN] A Fixed Asset
        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);

        // [GIVEN] FA Depreciation Book "FAB1" with a posting group setup
        CreateFADeprBookWithPostingGroup(FADepreciationBook, FixedAsset."No.", DeprBookCode[1]);

        // [GIVEN ] FA Deprection Book "FAB2"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DeprBookCode[2]);

        // [GIVEN] FA Ledger entry for book "FAB1" with non-zero amount
        MockFADepreciationLedgerEntry(FALedgerEntry, FixedAsset."No.", DeprBookCode[1]);

        // [WHEN] Run report 13402 for books "FAB1" and "FAB2"
        EnqueueParamsForCalcAndPostDeprDifferenceReport(
          DeprBookCode[1], DeprBookCode[2], WorkDate, WorkDate, WorkDate, LibraryUtility.GenerateGUID, false, true);

        Commit();

        RunCalcAndPostDeprDifferenceReport(FixedAsset."No.");
        // UI Handled by CalcAndPostDeprDifferenceRPH,PostingDeprDiffCFH,MessageHandlerWithEnqueue

        // [THEN] Depreciation Difference is posted
        Assert.AreEqual(DeprDiffPostedTxt, LibraryVariableStorage.DequeueText, 'DeprDiffPostedTxt must be equal to Report13402.Text13408');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure PostingDeprDiffCFH(Question: Text; var Reply: Boolean)
    var
        Expected: Text;
    begin
        if 0 <> StrPos(Question, CompletionStatsTok) then
            Reply := false
        else begin
            Expected := PostingDeprDiffTxt;
            Assert.AreEqual(Expected, Question, 'PostingDeprDiffTxt must be equal to Report13402.Text13409');
            Reply := true;
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
        HandledMessage := Message;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcAndPostDeprDifferenceRPH(var CalcAndPostDeprDifferenceRequestPage: TestRequestPage "Calc. and Post Depr. Diff.")
    var
        Value: Variant;
    begin
        LibraryVariableStorage.Dequeue(Value);
        CalcAndPostDeprDifferenceRequestPage."Depreciation Book Code 1".SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        CalcAndPostDeprDifferenceRequestPage."Depreciation Book Code 2".SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        CalcAndPostDeprDifferenceRequestPage."Starting Date".SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        CalcAndPostDeprDifferenceRequestPage."Ending Date".SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        CalcAndPostDeprDifferenceRequestPage."Posting Date".SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        CalcAndPostDeprDifferenceRequestPage."Document No.".SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        CalcAndPostDeprDifferenceRequestPage."Print Empty Lines".SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        CalcAndPostDeprDifferenceRequestPage."Post Depreciation Difference".SetValue(Value);

        CalcAndPostDeprDifferenceRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset"; FAPostingGroup: Code[20])
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAsset.Validate("FA Posting Group", FAPostingGroup);
        FixedAsset.Modify(true);
    end;

    local procedure CreateFixedAssetPostingGroup(var FixedAsset: Record "Fixed Asset"; ClearDeprDifferenceAcc: Boolean; ClearDeprDifferenceBalAcc: Boolean)
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        UpdateFAPostingGroup(FAPostingGroup, ClearDeprDifferenceAcc, ClearDeprDifferenceBalAcc);
        CreateFixedAsset(FixedAsset, FAPostingGroup.Code);
    end;

    local procedure CreateAndSetupFixedAsset(var FixedAsset: Record "Fixed Asset"; StartingDate: Date; FAPostingGroupCode: Code[20]; DepreciationBookCodeSUMU: Code[10]; DepreciationMethodSUMU: Enum "FA Depreciation Method"; EndingDateFormulaSUMU: Text; DecliningBalancePercentSUMU: Decimal; DepreciationBookCodeTax: Code[10]; DepreciationMethodTax: Enum "FA Depreciation Method"; EndingDateFormulaTax: Text; DecliningBalancePercentTax: Decimal; ClearDeprDifferenceAcc: Boolean; ClearDeprDifferenceBalAcc: Boolean)
    var
        FAClass: Record "FA Class";
    begin
        CreateFixedAssetPostingGroup(FixedAsset, ClearDeprDifferenceAcc, ClearDeprDifferenceBalAcc);
        LibraryFixedAsset.FindFAClass(FAClass);
        with FixedAsset do begin
            "FA Class Code" := FAClass.Code;
            Modify(true);
        end;

        FAPostingGroupCode := FixedAsset."FA Posting Group";

        CreateAndSetupFADepreciationBook(
          FixedAsset, FAPostingGroupCode, DepreciationBookCodeSUMU, DepreciationMethodSUMU,
          StartingDate, EndingDateFormulaSUMU, DecliningBalancePercentSUMU);
        CreateAndSetupFADepreciationBook(
          FixedAsset, FAPostingGroupCode, DepreciationBookCodeTax, DepreciationMethodTax,
          StartingDate, EndingDateFormulaTax, DecliningBalancePercentTax);
    end;

    local procedure CreateAndSetupFADepreciationBook(FixedAsset: Record "Fixed Asset"; FAPostingGroupCode: Code[20]; DepreciationBooKCode: Code[10]; DepreciationMethod: Enum "FA Depreciation Method"; StartDate: Date; EndingDateFormulaExpression: Text; DecliningBalancePercent: Decimal)
    var
        FADepreciationBook: Record "FA Depreciation Book";
        EndingDateFormula: DateFormula;
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBooKCode);
        with FADepreciationBook do begin
            Validate("FA Posting Group", FAPostingGroupCode);
            Validate("Depreciation Method", DepreciationMethod);
            Validate("Depreciation Starting Date", StartDate);
            if EndingDateFormulaExpression <> '' then begin
                Evaluate(EndingDateFormula, EndingDateFormulaExpression);
                Validate("Depreciation Ending Date", CalcDate(EndingDateFormula, StartDate));
            end;
            Validate("Declining-Balance %", DecliningBalancePercent);
            Modify(true);
        end;
    end;

    local procedure CreateDepreciationBook(DefaultRounding: Decimal; Integration: Boolean): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        CreateDepreciationJournalSetup(DepreciationBook);
        with DepreciationBook do begin
            "Default Final Rounding Amount" := DefaultRounding;
            "Use FA Ledger Check" := true;
            "Use Rounding in Periodic Depr." := true;
            "Use Same FA+G/L Posting Dates" := true;
            "G/L Integration - Acq. Cost" := Integration;
            "G/L Integration - Depreciation" := Integration;
            "G/L Integration - Write-Down" := Integration;
            "G/L Integration - Appreciation" := Integration;
            "G/L Integration - Custom 1" := Integration;
            "G/L Integration - Custom 2" := Integration;
            "G/L Integration - Disposal" := Integration;
            "G/L Integration - Maintenance" := Integration;
            "Allow more than 360/365 Days" := true;
            Modify;
        end;

        exit(DepreciationBook.Code);
    end;

    local procedure CreateDepreciationJournalSetup(var DepreciationBook: Record "Depreciation Book")
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        UpdateFAJournalSetup(FAJournalSetup);
    end;

    local procedure CreateFAJournalLineWithAmount(var FAJournalLine: Record "FA Journal Line"; FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingType: Enum "FA Journal Line Document Type"; PostingDate: Date; LineAmount: Decimal)
    var
        FAJournalBatch: Record "FA Journal Batch";
    begin
        CreateFAJournalBatch(FAJournalBatch);
        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        FAJournalLine.Validate("Document No.", FAJournalBatch.Name);
        FAJournalLine.Validate("Posting Date", PostingDate);
        FAJournalLine.Validate("FA Posting Date", PostingDate);
        FAJournalLine.Validate("FA Posting Type", FAPostingType);
        FAJournalLine.Validate("FA No.", FANo);
        FAJournalLine.Validate(Amount, LineAmount);
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Modify(true);
    end;

    local procedure CreateFADeprBookWithPostingGroup(var FADepreciationBook: Record "FA Depreciation Book"; FixedAssetNo: Code[20]; DeprBookCode: Code[10])
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAssetNo, DeprBookCode);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup.Code);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateAndPostPurchaseInvoice(PostingDate: Date; FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]; Quantity: Decimal; Cost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        with PurchaseHeader do begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Document Type"::Invoice, '');
            Validate(
              "Vendor Invoice No.", LibraryUtility.GenerateRandomCode(FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
            Validate("Posting Date", PostingDate);
            Validate("Message Type", "Message Type"::Message);
            Validate("Invoice Message", FixedAssetNo);
            Modify(true);
        end;

        CreatePurchaseLine(PurchaseHeader, FixedAssetNo, DepreciationBookCode, Quantity, Cost);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]; FAQuantity: Decimal; FACost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        with PurchaseLine do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, Type::"Fixed Asset", FixedAssetNo, FAQuantity);
            Validate("Depreciation Book Code", DepreciationBookCode);
            Validate("Direct Unit Cost", FACost);
            Modify(true);
        end;
    end;

    local procedure CreateAndPostAcqusitionLine(FANo: Code[20]; FAPostingType: Enum "FA Journal Line FA Posting Type"; DepreciationBookCode: Code[10]; PostingDate: Date; LineAmount: Decimal)
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        CreateFAJournalLineWithAmount(FAJournalLine, FANo, DepreciationBookCode, FAPostingType, PostingDate, LineAmount);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure CreateFAAndPostDepreciation(Amount: Decimal; StartingDate: Date; PostingDate: Date; DepreciationBookCodeSUMU: Code[10]; DepreciationBookCodeTax: Code[10]; DepreciationMethodTax: Enum "FA Depreciation Method"; EndingDateFormulaTax: Text; DecliningBalancePercentTax: Decimal; ClearDeprDifferenceAcc: Boolean; ClearDeprDifferenceBalAcc: Boolean): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        with FADepreciationBook do
            CreateAndSetupFixedAsset(
              FixedAsset, StartingDate, '',
              DepreciationBookCodeSUMU, "Depreciation Method"::"Straight-Line", '<3Y-1D>', 0,
              DepreciationBookCodeTax, DepreciationMethodTax, EndingDateFormulaTax, DecliningBalancePercentTax,
              ClearDeprDifferenceAcc, ClearDeprDifferenceBalAcc);

        with FixedAsset do begin
            CreateAndPostPurchaseInvoice(StartingDate, "No.", DepreciationBookCodeSUMU, 1, Amount);
            CreateAndPostAcqusitionLine(
              "No.", FAJournalLine."FA Posting Type"::"Acquisition Cost", DepreciationBookCodeTax, StartingDate, Amount);

            RunAndPostDepreciation("No.", DepreciationBookCodeSUMU, CalcDate('<1M-1D>', StartingDate), true, false);
            RunAndPostDepreciation("No.", DepreciationBookCodeSUMU, PostingDate, true, false);
            RunAndPostDepreciation("No.", DepreciationBookCodeTax, PostingDate, false, true);

            exit("No.");
        end
    end;

    local procedure CreateFAJournalBatch(var FAJournalBatch: Record "FA Journal Batch")
    var
        FAJournalTemplate: Record "FA Journal Template";
    begin
        FAJournalTemplate.SetRange(Recurring, false);
        LibraryFixedAsset.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
    end;

    local procedure MockFADepreciationLedgerEntry(var FALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20]; DeprBookCode: Code[10])
    begin
        with FALedgerEntry do begin
            Init;
            "FA No." := FANo;
            "Depreciation Book Code" := DeprBookCode;
            "FA Posting Category" := "FA Posting Category"::"Bal. Disposal";
            "FA Posting Type" := "FA Posting Type"::Depreciation;
            "Posting Date" := WorkDate;
            "Depr. Difference Posted" := false;
            Amount := LibraryRandom.RandDec(100, 2);
            Insert;
        end;
    end;

    local procedure RunAndPostDepreciation(FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]; PostingDate: Date; InsertBalanceAccount: Boolean; Tax: Boolean)
    begin
        RunCalculateDepreciation(FixedAssetNo, DepreciationBookCode, PostingDate, InsertBalanceAccount);
        if Tax then
            PostTaxDepreciation(DepreciationBookCode, FixedAssetNo)
        else
            PostDepreciation(DepreciationBookCode);
    end;

    local procedure RunCalculateDepreciation(FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]; PostingDate: Date; InsertBalanceAccount: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        CalculateDepreciation: Report "Calculate Depreciation";
    begin
        Clear(CalculateDepreciation);
        FixedAsset.SetRange("No.", FixedAssetNo);

        CalculateDepreciation.SetTableView(FixedAsset);
        CalculateDepreciation.InitializeRequest(
          DepreciationBookCode, PostingDate, false, 0, PostingDate, FixedAssetNo, FixedAsset.Description, InsertBalanceAccount);
        CalculateDepreciation.UseRequestPage(false);
        CalculateDepreciation.Run;
    end;

    local procedure PostDepreciation(DepreciationBookCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        DocumentNo: Code[20];
    begin
        FAJournalSetup.Get(DepreciationBookCode, '');
        with GenJournalLine do begin
            SetRange("Journal Template Name", FAJournalSetup."Gen. Jnl. Template Name");
            SetRange("Journal Batch Name", FAJournalSetup."Gen. Jnl. Batch Name");
            FindSet();
            GenJournalBatch.Get("Journal Template Name", "Journal Batch Name");

            DocumentNo := NoSeriesManagement.GetNextNo(GenJournalBatch."No. Series", WorkDate, false);
            repeat
                Validate("Document No.", DocumentNo);
                Validate(Description, FAJournalSetup."Gen. Jnl. Batch Name");
                Modify(true);
            until Next = 0;
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostTaxDepreciation(DepreciationBookCode: Code[10]; FixedAssetNo: Code[20])
    var
        FAJournalLine: Record "FA Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        FAJournalBatch: Record "FA Journal Batch";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        DocumentNo: Code[20];
    begin
        FAJournalSetup.Get(DepreciationBookCode, '');
        with FAJournalLine do begin
            SetRange("Journal Template Name", FAJournalSetup."Gen. Jnl. Template Name");
            SetRange("Journal Batch Name", FAJournalSetup."Gen. Jnl. Batch Name");
            SetRange("FA No.", FixedAssetNo);
            FindSet();
            FAJournalBatch.Get("Journal Template Name", "Journal Batch Name");

            DocumentNo := NoSeriesManagement.GetNextNo(FAJournalBatch."No. Series", WorkDate, false);
            repeat
                Validate("Document No.", DocumentNo);
                Validate(Description, FAJournalSetup."Gen. Jnl. Batch Name");
                Modify(true);
            until Next = 0;
        end;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure UpdateFAPostingGroup(var FAPostingGroup: Record "FA Posting Group"; ClearDeprDifferenceAcc: Boolean; ClearDeprDifferenceBalAcc: Boolean)
    var
        FAPostingGroup2: Record "FA Posting Group";
        RecRef: RecordRef;
    begin
        FAPostingGroup2.Init();
        FAPostingGroup2.SetFilter("Acquisition Cost Account", '<>''''');
        RecRef.GetTable(FAPostingGroup2);
        LibraryUtility.FindRecord(RecRef);
        RecRef.SetTable(FAPostingGroup2);
        FAPostingGroup.TransferFields(FAPostingGroup2, false);
        if ClearDeprDifferenceAcc then
            FAPostingGroup."Depr. Difference Acc." := '';
        if ClearDeprDifferenceBalAcc then
            FAPostingGroup."Depr. Difference Bal. Acc." := '';
        FAPostingGroup.Modify(true);
    end;

    local procedure UpdateFAJournalSetup(var FAJournalSetup: Record "FA Journal Setup")
    var
        FAJournalSetup2: Record "FA Journal Setup";
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FAJournalSetup2.SetRange("Depreciation Book Code", FASetup."Default Depr. Book");
        FAJournalSetup2.FindFirst;
        FAJournalSetup.TransferFields(FAJournalSetup2, false);
        FAJournalSetup.Modify(true);
    end;

    local procedure EnqueueParamsForCalcAndPostDeprDifferenceReport(DepreciationBookCodeSUMU: Code[10]; DepreciationBookCodeTax: Code[10]; StartingDate: Date; EndingDate: Date; PostingDate: Date; DocumentNo: Code[20]; PrintEmptyLines: Boolean; PostDepreciationDifference: Boolean)
    begin
        LibraryVariableStorage.Enqueue(DepreciationBookCodeSUMU);
        LibraryVariableStorage.Enqueue(DepreciationBookCodeTax);
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(PrintEmptyLines);
        LibraryVariableStorage.Enqueue(PostDepreciationDifference);
    end;

    local procedure RunCalcAndPostDeprDifferenceReport(FixedAssetFilter: Text)
    var
        FixedAsset: Record "Fixed Asset";
        CalcAndPostDeprDiffReport: Report "Calc. and Post Depr. Diff.";
    begin
        FixedAsset.SetFilter("No.", FixedAssetFilter);
        CalcAndPostDeprDiffReport.SetTableView(FixedAsset);
        CalcAndPostDeprDiffReport.UseRequestPage(true);
        CalcAndPostDeprDiffReport.Run;
    end;

    local procedure RunCalcAndPostDeprDifferenceReportWithEnqueue(DepreciationBookCodeSUMU: Code[10]; DepreciationBookCodeTax: Code[10]; StartingDate: Date; EndingDate: Date; PostingDate: Date; DocumentNo: Code[20]; PrintEmptyLines: Boolean; PostDepreciationDifference: Boolean; FixedAssetFilter: Text)
    begin
        EnqueueParamsForCalcAndPostDeprDifferenceReport(
          DepreciationBookCodeSUMU, DepreciationBookCodeTax, StartingDate, EndingDate,
          PostingDate, DocumentNo, PrintEmptyLines, PostDepreciationDifference);

        RunCalcAndPostDeprDifferenceReport(FixedAssetFilter);
        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure VerifyCalcAndPostDeprDifferenceReportWithZeroDifference()
    begin
        LibraryReportDataset.LoadDataSetFile;
        Assert.IsFalse(
          LibraryReportDataset.FindRow('DifferenceAmt', 0) > -1,
          StrSubstNo(ZeroDifferenceLineErr, 'Calc. and Post Depr. Diff.'));
    end;

    local procedure VerifyCalcAndPostDeprDifferenceReportWithEmptyLines()
    var
        DifferenceAmt: Variant;
    begin
        LibraryReportDataset.LoadDataSetFile;
        if LibraryReportDataset.GetNextRow then begin
            LibraryReportDataset.FindCurrentRowValue('DifferenceAmt', DifferenceAmt);
            Assert.AreEqual(0, DifferenceAmt, StrSubstNo(DifferenceAmtErr, 0));
        end
    end;

    local procedure VerifyCalcAndPostDeprDifferenceReportWithDifference()
    var
        DifferenceAmt: Variant;
    begin
        LibraryReportDataset.LoadDataSetFile;
        if LibraryReportDataset.GetNextRow then begin
            LibraryReportDataset.FindCurrentRowValue('DifferenceAmt', DifferenceAmt);
            Assert.AreNotEqual(0, DifferenceAmt, StrSubstNo(DifferenceAmtErr, 0));
        end
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DepreciationCalcConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerWithEnqueue(Message: Text)
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;
}

