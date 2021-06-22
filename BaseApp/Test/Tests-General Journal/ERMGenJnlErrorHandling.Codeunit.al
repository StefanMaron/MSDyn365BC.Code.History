codeunit 134932 "ERM Gen. Jnl. Error Handling"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [UI] [Journal Error Handling]
    end;

    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryRandom: Codeunit "Library - Random";
        LibraryDimension: Codeunit "Library - Dimension";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        BackgroundErrorCheckFeatureEnabled: Boolean;
        DummyErr: Label 'Dummy error';
        TestFieldEmptyValueErr: Label '%1 must not be empty.', Comment = '%1 - field caption';
        TestFieldValueErr: Label '%1 must be equal to %2.', Comment = '%1 - field caption, %2 - field value';
        DocumentOutOfBalanceErr: Label 'Document No. %1 is out of balance by %2', Comment = '%1 - document number, %2 = amount';
        FieldErrorErr: Label '%1 %2', Comment = '%1 - field name, %2 - error message';
        FieldMustNotBeErr: Label '%1 must not be %2', Comment = '%1 - field name, %2 - field value';
        SameSignErr: Label '%1 must have the same sign as %2', Comment = '%1 - field name, %2 - field name';
        OutOfBalanceFilterTxt: Label '*is out of balance by*';
        OtherIssuesTxt: Label '(+%1 other issues)', comment = '%1 - number of issues';
        ExtendingGenJnlCheckLineTxt: Label 'ExtendingGenJnlCheckLine', Locked = true;
        LogTestFieldOptionTxt: Label 'LogTestFieldOption', Locked = true;
        DimErr: Label 'Select a Dimension Value Code for the Dimension Code %1 for G/L Account %2.', Comment = '%1 - dimension code, %2 - account number';
        DisabledFeatureErr: Label 'Enabled must be equal to ''All Users''  in Feature Key: ID=JournalErrorBackgroundCheck';
        OnBeforeRunCheckTxt: Label 'OnBeforeRunCheck', Locked = true;

    [Test]
    procedure BackgroundErrorCheckInvisibleIfFeatureIsOff()
    var
        GeneralJournalBatches: TestPage "General Journal Batches";
        ERMGenJnlErrorHandling: Codeunit "ERM Gen. Jnl. Error Handling";
    begin
        Initialize();
        // [GIVEN] Feature is off
        BindSubscription(ERMGenJnlErrorHandling);

        // [WHEN] Run "General Journal Batches" page
        GeneralJournalBatches.Trap();
        Page.Run(Page::"General Journal Batches");

        // [THEN] BackgroundErrorCheck control should be invisible
        Assert.IsFalse(
            GeneralJournalBatches.BackgroundErrorCheck.Visible(), 'BackgroundErrorCheck should be invisible')
    end;

    [Test]
    procedure BackgroundErrorCheckVisibleIfFeatureIsOn()
    var
        GeneralJournalBatches: TestPage "General Journal Batches";
        ERMGenJnlErrorHandling: Codeunit "ERM Gen. Jnl. Error Handling";
    begin
        // [FEATURE] [UI]
        Initialize();
        // [GIVEN] Feature is on
        EnableFeature(ERMGenJnlErrorHandling);

        // [WHEN] Run "General Journal Batches" page
        GeneralJournalBatches.Trap();
        Page.Run(Page::"General Journal Batches");

        // [THEN] BackgroundErrorCheck control should be invisible and can be modified
        Assert.IsTrue(
            GeneralJournalBatches.BackgroundErrorCheck.Visible(), 'BackgroundErrorCheck should be visible');
        GeneralJournalBatches.BackgroundErrorCheck.SetValue(Format(true));
    end;

    [Test]
    procedure BackgroundErrorCheckCannotBeEnabledIfFeatureIsOff()
    var
        GeneralJournalBatch: Record "Gen. Journal Batch";
        ERMGenJnlErrorHandling: Codeunit "ERM Gen. Jnl. Error Handling";
    begin
        // [FEATURE] [UT]
        Initialize();
        // [GIVEN] Feature is off
        BindSubscription(ERMGenJnlErrorHandling);

        // [WHEN] Set "Background Error Check" to true
        asserterror GeneralJournalBatch.Validate("Background Error Check", true);

        // [THEN] Error: "Enabled must be 'All Users' in Feature Key"
        Assert.ExpectedError(DisabledFeatureErr);
    end;

    [Test]
    procedure BackgroundErrorCheckCanBeEnabledIfFeatureIsOn()
    var
        GeneralJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        ERMGenJnlErrorHandling: Codeunit "ERM Gen. Jnl. Error Handling";
    begin
        // [FEATURE] [UT]
        Initialize();
        // [GIVEN] Feature is on
        EnableFeature(ERMGenJnlErrorHandling);
        // [GIVEN] GeneralJournalBatch, where "Background Error Check" is false
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GeneralJournalBatch, GenJournalTemplate.Name);

        // [WHEN] Set "Background Error Check" to true
        GeneralJournalBatch.Validate("Background Error Check", true);

        // [THEN] "Background Error Check" is true
        GeneralJournalBatch.TestField("Background Error Check", true);
    end;

    [Test]
    procedure BackgroundErrorCheckCanBeDisabledIfFeatureIsOn()
    var
        GeneralJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        ERMGenJnlErrorHandling: Codeunit "ERM Gen. Jnl. Error Handling";
    begin
        // [FEATURE] [UT]
        Initialize();
        // [GIVEN] Feature is on
        EnableFeature(ERMGenJnlErrorHandling);
        // [GIVEN] GeneralJournalBatch, where "Background Error Check" is true
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GeneralJournalBatch, GenJournalTemplate.Name);
        GeneralJournalBatch."Background Error Check" := true;
        GeneralJournalBatch.Modify();

        // [WHEN] Set "Background Error Check" to true
        GeneralJournalBatch.Validate("Background Error Check", false);

        // [THEN] "Background Error Check" is false
        GeneralJournalBatch.TestField("Background Error Check", false);
    end;

    [Test]
    procedure BackgroundErrorCheckClearedIfFeatureIsDisabling()
    var
        GeneralJournalBatch: Record "Gen. Journal Batch";
        FeatureKey: Record "Feature Key";
        GenJournalTemplate: Record "Gen. Journal Template";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
    begin
        // [FEATURE] [UT]
        Initialize();
        // [GIVEN] Feature is on (mock)
        FeatureKey.ID := JournalErrorsMgt.GetFeatureKey();
        FeatureKey.Enabled := FeatureKey.Enabled::"All Users";

        // [GIVEN] GeneralJournalBatch, where "Background Error Check" is true
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GeneralJournalBatch, GenJournalTemplate.Name);
        GeneralJournalBatch."Background Error Check" := true;
        GeneralJournalBatch.Modify();

        // [WHEN] Disable the feature 
        FeatureKey.ID := JournalErrorsMgt.GetFeatureKey();
        FeatureKey.Validate(Enabled, FeatureKey.Enabled::None);

        // [THEN] "Background Error Check" is false
        GeneralJournalBatch.Find('=');
        GeneralJournalBatch.TestField("Background Error Check", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NumberOfBatchErrors()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Batch Errors field shows correct number of errors for all lines in batch
        Initialize();

        // [GIVEN] Create 5 single line documents with zero amount for new batch "XXX"
        CreateZeroAmountJournalLines(GenJournalLine);

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] Number for batch errors = 5
        GeneralJournal.JournalErrorsFactBox.NumberOfBatchErrors.AssertEquals(GetNumberOfLines(GenJournalLine));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NumberOfDocumentOutOfBalanceErrors()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
        TotalBalance: Decimal;
    begin
        // [SCENARIO 355641] Multiline out of balance document gives one common batch error
        Initialize();

        // [GIVEN] Create 5 line document for new batch "XXX" with balance 100
        CreateMultiLineGenJnlDocOutOfBalance(GenJournalLine, TotalBalance);

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] Number for batch errors = 1
        GeneralJournal.JournalErrorsFactBox.NumberOfBatchErrors.AssertEquals(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NumberOfLinesChecked()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Lines Checked field shows correct number of lines in batch
        Initialize();

        // [GIVEN] Create 6 line document 
        CreateMultiLineGenJnlDocZeroBalance(GenJournalLine);

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] Lines Checked = 6
        GeneralJournal.JournalErrorsFactBox.NumberOfLinesChecked.AssertEquals(GetNumberOfLines(GenJournalLine));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NumberOfLinesWithErrors()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] "Lines with Issues" field shows correct number of lines with errors
        Initialize();

        // [GIVEN] Create 5 single document lines 
        CreateGenJournalLines(GenJournalLine, LibraryRandom.RandIntInRange(5, 10));

        // [GIVEN] Clear amount and document number for first and last lines
        SetBatchFilter(GenJournalLine);
        GenJournalLine.FindFirst();
        ClearAmountAndDocumentNo(GenJournalLine);

        GenJournalLine.FindLast();
        ClearAmountAndDocumentNo(GenJournalLine);

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] "Lines with Issues" = 2
        GeneralJournal.JournalErrorsFactBox.NumberOfLinesWithErrors.AssertEquals(2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrentLineTwoErrors()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Current line group shows 2 errors
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with 2 errors: empty document number and amount 
        CreateGenJournalLine(GenJournalLine);
        ClearAmountAndDocumentNo(GenJournalLine);

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] First error line is "Document No. must not be empty" 
        GeneralJournal.JournalErrorsFactBox.Error1.AssertEquals(StrSubstNo(TestFieldEmptyValueErr, GenJournalLine.FieldCaption("Document No.")));
        GeneralJournal.JournalErrorsFactBox.Error2.AssertEquals(StrSubstNo(TestFieldEmptyValueErr, GenJournalLine.FieldCaption(Amount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrentLineThreeErrors()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Second row shows message "(+2 other issues)" in case of 3 errors
        Initialize();

        // [GIVEN] Set allwow posign to = 31.12.2020
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate() - 1);

        // [GIVEN] Create journal line for new batch "XXX" with 3 errors: empty document number, amount and posting date = 01.01.2021
        CreateGenJournalLine(GenJournalLine);
        GenJournalLine.Validate(Amount, 0);
        GenJournalLine."Document No." := '';
        GenJournalLine.TestField("Posting Date", WorkDate());
        GenJournalLine.Modify();

        // [WHEN] Open general journal for batch "XXX"
        Commit();
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] Second line is "(+2 other issues)"
        GeneralJournal.JournalErrorsFactBox.Error2.AssertEquals(StrSubstNo(OtherIssuesTxt, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BatchErrorsDrillDown()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
        ErrorMessages: TestPage "Error Messages";
        TotalBalance: Decimal;
        GLSetup: Record "General Ledger Setup";
    begin
        // [SCENARIO 355641] DrillDown from Batch Errors field opens list of errors
        Initialize();
        GLSetup.get;

        // [GIVEN] Create 5 line document "DOC" for new batch "XXX" with balance 100
        CreateMultiLineGenJnlDocOutOfBalance(GenJournalLine, TotalBalance);

        // [GIVEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [WHEN] DrillDown from Batch Erros fields
        ErrorMessages.Trap();
        GeneralJournal.JournalErrorsFactBox.NumberOfBatchErrors.Drilldown();

        // [THEN] Error Messages page opened with Description = "Document DOC is out of balance by 100"
        ErrorMessages.Description.AssertEquals(StrSubstNo(DocumentOutOfBalanceErr, GenJournalLine."Document No.", TotalBalance));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendingGenJnlCheckLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        ERMGenJnlErrorHandling: Codeunit "ERM Gen. Jnl. Error Handling";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 355641] Journal errors log shows errors from extension of codeunit "Gen. Jnl.-Check Line" 
        Initialize();

        // [GIVEN] Subscribe to OnAfterCheckGenJnlLine event to raise "Dummy error"
        BindSubscription(ERMGenJnlErrorHandling);

        // [GIVEN] Create journal line
        CreateGenJournalLine(GenJournalLine);
        // [GIVEN] Set Description = 'ExtendingGenJnlCheckLine' for the subscriber 
        GenJournalLine.Description := ExtendingGenJnlCheckLineTxt;
        GenJournalLine.Modify();

        // [WHEN] Mock run codeunit "Gen. Jnl.-Check Line" with LogErrorMode=True
        MockGenJnlCheckLineRun(GenJournalLine, TempErrorMessage);

        // [THEN] Error message has Description = "Dummy error"
        TempErrorMessage.TestField(Description, DummyErr);
        TempErrorMessage.TestField("Context Record ID", GenJournalLine.RecordId());

        UnbindSubscription(ERMGenJnlErrorHandling);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LogTestFieldOption()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        ERMGenJnlErrorHandling: Codeunit "ERM Gen. Jnl. Error Handling";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 355641] Journal errors log shows TestField error for option type field with option caption 
        Initialize();

        // [GIVEN] Subscribe to OnAfterCheckGenJnlLine event to raise option field error
        BindSubscription(ERMGenJnlErrorHandling);

        // [GIVEN] Create journal line
        CreateGenJournalLine(GenJournalLine);
        // [GIVEN] Set Description = 'LogTestFieldOption' for the subscriber 
        GenJournalLine.Description := LogTestFieldOptionTxt;
        GenJournalLine.Modify();

        // [WHEN] Mock run codeunit "Gen. Jnl.-Check Line" with LogErrorMode=True
        MockGenJnlCheckLineRun(GenJournalLine, TempErrorMessage);

        // [THEN] Error message has Description = "IC Direction must be Outgoing"
        TempErrorMessage.TestField(Description, StrSubstNo(TestFieldValueErr, GenJournalLine.FieldCaption("IC Direction"), GenJournalLine."IC Direction"::Outgoing));

        UnbindSubscription(ERMGenJnlErrorHandling);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalLineErrorsFactBoxTestFieldNotEmpty()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Message for error caused by test field against empty value is "FieldXXX must not be empty"
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with empty document 
        CreateGenJournalLine(GenJournalLine);
        GenJournalLine."Document No." := '';
        GenJournalLine.Modify();

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        GeneralJournal.JournalErrorsFactBox.Error1.AssertEquals(StrSubstNo(TestFieldEmptyValueErr, GenJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalLineErrorsFactBoxTestFieldValue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Message for error caused by test field against some value is "FieldXXX must be equal to YYY."
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with "Pmt. Discount Date" = 25.01.2020 
        CreateGenJournalLine(GenJournalLine);
        GenJournalLine."Pmt. Discount Date" := WorkDate();
        GenJournalLine.Modify();

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Pmt. Discount Date must be equal to ''."
        GeneralJournal.JournalErrorsFactBox.Error1.AssertEquals(StrSubstNo(TestFieldValueErr, GenJournalLine.FieldCaption("Pmt. Discount Date"), ''''''));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalLineErrorsFactBoxFieldError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICPartner: Record "IC Partner";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Message for error caused by FieldError with error message parameters is "FieldXXX ErrorMessageYYY"
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with Amount = 100, "Amount (LCY)" = -100
        CreateGenJournalLine(GenJournalLine);
        LibraryERM.CreateICPartner(ICPartner);
        GenJournalLine.Amount := LibraryRandom.RandDec(100, 2);
        GenJournalLine."Amount (LCY)" := -LibraryRandom.RandDec(100, 2);
        GenJournalLine.Modify();

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Amount (LCY) must have the same sign as Amount"
        GeneralJournal.JournalErrorsFactBox.Error1.AssertEquals(
            StrSubstNo(
                SameSignErr, GenJournalLine.FieldCaption("Amount (LCY)"), GenJournalLine.FieldCaption(Amount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalLineErrorsFactBoxFieldErrorNoErrorMessage()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICPartner: Record "IC Partner";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Message for error caused by FieldError without parameters is "FieldXXX must not be YYY."
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with Account Type = "IC Partner""
        CreateGenJournalLine(GenJournalLine);
        LibraryERM.CreateICPartner(ICPartner);
        GenJournalLine."Account Type" := "Gen. Journal Account Type"::"IC Partner";
        GenJournalLine."Account No." := ICPartner.Code;
        GenJournalLine.Modify();

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Account Type must not be IC Partner."
        GeneralJournal.JournalErrorsFactBox.Error1.AssertEquals(
            StrSubstNo(
                FieldMustNotBeErr, GenJournalLine.FieldCaption("Account Type"), "Gen. Journal Account Type"::"IC Partner"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalBatchBackgroundErrorCheckYes()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Background check related controls are visible on the general journal page for batch with "Background Error "Check = Yes
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with "Pmt. Discount Date" = 25.01.2020 
        CreateGenJournalLine(GenJournalLine);
        GenJournalLine."Pmt. Discount Date" := WorkDate();
        GenJournalLine.Modify();

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] Action items are visible
        Assert.IsTrue(GeneralJournal.ShowLinesWithErrors.Visible(), 'ShowLinesWithErrors must be visible');
        Assert.IsTrue(GeneralJournal.ShowAllLines.Visible(), 'ShowAllLines must be visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalBatchBackgroundErrorCheckNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Background check related controls are invisible on the general journal page for batch with "Background Error "Check = No
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with "Pmt. Discount Date" = 25.01.2020 
        CreateGenJournalLine(GenJournalLine);
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        GenJournalBatch.Validate("Background Error Check", false);
        GenJournalBatch.Modify();

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] Action items are invisible
        Assert.IsFalse(GeneralJournal.ShowLinesWithErrors.Visible(), 'ShowLinesWithErrors must be invisible');
        Assert.IsFalse(GeneralJournal.ShowAllLines.Visible(), 'ShowAllLines must be invisible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeMultilineDocumentOutOfBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        xGenJournalLine: Record "Gen. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        CheckGenJnlLineBackgr: Codeunit "Check Gen. Jnl. Line. Backgr.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 355641] Unit test to check errors when make multiline document out of balance
        Initialize();

        // [GIVEN] Create 6 line document with zero balance 
        CreateMultiLineGenJnlDocZeroBalance(GenJournalLine);

        // [GIVEN] Increase first line amount by 100 to make document out of balance 
        GenJournalLine.FindFirst();
        xGenJournalLine := GenJournalLine;
        GenJournalLine.Validate(Amount, GenJournalLine.Amount + LibraryRandom.RandDec(100, 2));
        GenJournalLine.Modify();

        // [WHEN] Mock line modified
        Commit();
        MockLineModified(xGenJournalLine, GenJournalLine, TempErrorMessage);

        // [THEN] Number of "out of balance" errors = 6
        TempErrorMessage.SetFilter(Description, OutOfBalanceFilterTxt);
        Assert.AreEqual(GenJournalLine.Count(), TempErrorMessage.Count(), 'Invalid number of errors');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeMultilineDocumentOutOfBalanceByClearDocumentNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        xGenJournalLine: Record "Gen. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        CheckGenJnlLineBackgr: Codeunit "Check Gen. Jnl. Line. Backgr.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 355641] Unit test to check errors when make one of multiline document line empty document number
        Initialize();

        // [GIVEN] Create 6 line document with zero balance 
        CreateMultiLineGenJnlDocZeroBalance(GenJournalLine);

        // [GIVEN] Set first line document number empty
        GenJournalLine.FindFirst();
        xGenJournalLine := GenJournalLine;
        GenJournalLine.Validate("Document No.", '');
        GenJournalLine.Modify();

        // [WHEN] RunCheck to mock move from first line to second line 
        Commit();
        MockLineModified(xGenJournalLine, GenJournalLine, TempErrorMessage);

        // [THEN] Number of "out of balance" errors = 6
        TempErrorMessage.SetFilter(Description, OutOfBalanceFilterTxt);
        Assert.AreEqual(GenJournalLine.Count(), TempErrorMessage.Count(), 'Invalid number of errors');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeMultilineDocumentOutOfBalanceByUpdatePostingDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        xGenJournalLine: Record "Gen. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;

    begin
        // [FEATURE] [UT]
        // [SCENARIO 355641] Unit test to check errors when change the Posting Date for one of multiline document line 
        Initialize();

        // [GIVEN] Create 6 line document with zero balance and "Posting Date" = 22.01.2020
        CreateMultiLineGenJnlDocZeroBalance(GenJournalLine);

        // [GIVEN] Set first line "Posting Date" = 23.01.2020
        GenJournalLine.FindFirst();
        xGenJournalLine := GenJournalLine;
        GenJournalLine.Validate("Posting Date", CalcDate('<+1D>', WorkDate()));
        GenJournalLine.Modify();

        // [WHEN] RunCheck to mock move from first line to second line 
        MockLineModified(xGenJournalLine, GenJournalLine, TempErrorMessage);

        // [THEN] Number of "out of balance" errors = 6
        TempErrorMessage.SetFilter(Description, OutOfBalanceFilterTxt);
        Assert.AreEqual(GenJournalLine.Count(), TempErrorMessage.Count(), 'Invalid number of errors');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeTwoMultilineDocumentsOutOfBalanceByMovingToThirdDocument()
    var
        GenJournalLine: array[3] of Record "Gen. Journal Line";
        xGenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        TempErrorMessage: Record "Error Message" temporary;
        xDocumentNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 355641] Unit test to check errors when change the document number from DOC1 to DOC2 and move to DOC3
        Initialize();

        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        // [GIVEN] Create 6 line zero balance document DOC1  
        CreateMultiLineGenJnlDocZeroBalance(GenJournalBatch, GenJournalLine[1]);

        // [GIVEN] Create 6 line zero balance document DOC2  
        CreateMultiLineGenJnlDocZeroBalance(GenJournalBatch, GenJournalLine[2]);
        // [GIVEN] Create 6 line zero balance document DOC3  
        CreateMultiLineGenJnlDocZeroBalance(GenJournalBatch, GenJournalLine[3]);

        // [GIVEN] For first line of DOC2 set "Document No." = DOC1
        GenJournalLine[2].FindFirst();
        xDocumentNo := GenJournalLine[2]."Document No.";
        GenJournalLine[2]."Document No." := GenJournalLine[1]."Document No.";
        GenJournalLine[2].Modify();

        // [GIVEN] RunCheck to mock full batch check
        MockFullBatchCheck(
            GenJournalLine[1]."Journal Template Name",
            GenJournalLine[1]."Journal Batch Name",
            TempErrorMessage);

        // [THEN] Number of "out of balance" errors = 12
        Assert.AreEqual(GenJournalLine[1].Count() + GenJournalLine[2].Count(), TempErrorMessage.Count(), 'Invalid number of errors');

        // [GIVEN] Mock first line of DOC2 as xRec before update "Document No."
        GenJournalLine[2].Find();
        xGenJournalLine := GenJournalLine[2];

        // [GIVEN] For first line of DOC2 set back "Document No." = DOC2
        GenJournalLine[2]."Document No." := xDocumentNo;
        GenJournalLine[2].Modify();

        // [WHEN] RunCheck to mock move from first line of DOC2 to line of DOC3 
        MockLineModified(xGenJournalLine, GenJournalLine[2], TempErrorMessage);

        // [THEN] Number of errors became 0
        Assert.AreEqual(0, TempErrorMessage.Count(), 'Invalid number of errors');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashReceiptJournalSunshine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [SCENARIO 355641] Journal errors factbox works for cash receipt journal
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with empty document 
        CreateEmptyDocGenJournalLineForTemplate(GenJournalLine, "Gen. Journal Template Type"::"Cash Receipts", Page::"Cash Receipt Journal");

        // [WHEN] Open cash receipt journal for batch "XXX"
        CashReceiptJournal.Trap();
        Page.Run(Page::"Cash Receipt Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        CashReceiptJournal.JournalErrorsFactBox.Error1.AssertEquals(StrSubstNo(TestFieldEmptyValueErr, GenJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesJournalSunshine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [SCENARIO 355641] Journal errors factbox works for sales journal
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with empty document 
        CreateEmptyDocGenJournalLineForTemplate(GenJournalLine, "Gen. Journal Template Type"::Sales, Page::"Sales Journal");

        // [WHEN] Open sales journal for batch "XXX"
        SalesJournal.Trap();
        Page.Run(Page::"Sales Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        SalesJournal.JournalErrorsFactBox.Error1.AssertEquals(StrSubstNo(TestFieldEmptyValueErr, GenJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseJournalSunshine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [SCENARIO 355641] Journal errors factbox works for purchase journal
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with empty document 
        CreateEmptyDocGenJournalLineForTemplate(GenJournalLine, "Gen. Journal Template Type"::Purchases, Page::"Purchase Journal");

        // [WHEN] Open purchase journal for batch "XXX"
        PurchaseJournal.Trap();
        Page.Run(Page::"Purchase Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        PurchaseJournal.JournalErrorsFactBox.Error1.AssertEquals(StrSubstNo(TestFieldEmptyValueErr, GenJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentJournalSunshine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 355641] Journal errors factbox works for payment journal
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with empty document 
        CreateEmptyDocGenJournalLineForTemplate(GenJournalLine, "Gen. Journal Template Type"::Payments, Page::"Payment Journal");

        // [WHEN] Open payment journal for batch "XXX"
        PaymentJournal.Trap();
        Page.Run(Page::"Payment Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        PaymentJournal.JournalErrorsFactBox.Error1.AssertEquals(StrSubstNo(TestFieldEmptyValueErr, GenJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedAssetGLJournalSunshine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FixedAssetGLJournal: TestPage "Fixed Asset G/L Journal";
    begin
        // [SCENARIO 355641] Journal errors factbox works for fixed assets G/L journal
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with empty document 
        CreateEmptyDocGenJournalLineForTemplate(GenJournalLine, "Gen. Journal Template Type"::Assets, Page::"Fixed Asset G/L Journal");

        // [WHEN] Open fixed assets G/L journal for batch "XXX"
        FixedAssetGLJournal.Trap();
        Page.Run(Page::"Fixed Asset G/L Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        FixedAssetGLJournal.JournalErrorsFactBox.Error1.AssertEquals(StrSubstNo(TestFieldEmptyValueErr, GenJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICGeneralJournalSunshine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICGeneralJournal: TestPage "IC General Journal";
    begin
        // [SCENARIO 355641] Journal errors factbox works for fixed assets IC General Journal
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with empty document 
        CreateEmptyDocGenJournalLineForTemplate(GenJournalLine, "Gen. Journal Template Type"::Intercompany, Page::"IC General Journal");

        // [WHEN] Open IC general journal for batch "XXX"
        ICGeneralJournal.Trap();
        Page.Run(Page::"IC General Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        ICGeneralJournal.JournalErrorsFactBox.Error1.AssertEquals(StrSubstNo(TestFieldEmptyValueErr, GenJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobGLJournalSunshine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JobGLJournal: TestPage "Job G/L Journal";
    begin
        // [SCENARIO 355641] Journal errors factbox works for Jobs G/L journal
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with empty document 
        CreateEmptyDocGenJournalLineForTemplate(GenJournalLine, "Gen. Journal Template Type"::Jobs, Page::"Job G/L Journal");

        // [WHEN] Open Jobs G/L journal for batch "XXX"
        JobGLJournal.Trap();
        Page.Run(Page::"Job G/L Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        JobGLJournal.JournalErrorsFactBox.Error1.AssertEquals(StrSubstNo(TestFieldEmptyValueErr, GenJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteJnlLineWithErrors()
    var
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        ErrorHandlingParameters: Record "Error Handling Parameters";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 355641] Errors for deleted journal lines removed from error messages
        Initialize();

        // [GIVEN] journal lines with empty amount: Line1 and Line2
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[1], GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            "Gen. Journal Document Type"::" ", "Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 0);

        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[2], GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            "Gen. Journal Document Type"::" ", "Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 0);

        // [GIVEN] Mock 2 error messages for Line1 and Line2
        MockFullBatchCheck(
            GenJournalLine[1]."Journal Template Name",
            GenJournalLine[1]."Journal Batch Name",
            TempErrorMessage);

        // [GIVEN] Mock Line2 deleted
        JournalErrorsMgt.InsertDeletedLine(GenJournalLine[2]);
        GenJournalLine[2].Delete();

        // [WHEN] Run CleanTempErrorMessages 
        SetErrorHandlingParameters(ErrorHandlingParameters, GenJournalLine[1], GenJournalLine[1]."Document No.", GenJournalLine[1]."Posting Date",
            GenJournalLine[1]."Document No.", GenJournalLine[1]."Posting Date", false, false);
        BackgroundErrorHandlingMgt.CleanTempErrorMessages(TempErrorMessage, ErrorHandlingParameters);

        // [THEN] Error message about Line2 deleted
        TempErrorMessage.Reset();
        TempErrorMessage.SetRange("Context Record ID", GenJournalLine[2].RecordId);
        Assert.IsTrue(TempErrorMessage.IsEmpty, 'Error message for line 2 has to be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteJnlLinesWithErrorsToMakeZeroDocsBalance()
    var
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        ExtraGenJournalLine: array[2] of Record "Gen. Journal Line";
        xGenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorHandlingParameters: Record "Error Handling Parameters";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        xDocumentNo: Code[20];
    begin
        // [FEATURE] 
        // [SCENARIO 355641] Balance checked for deleted lines 
        Initialize();

        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        // [GIVEN] Create 6 line zero balance document DOC1  
        CreateMultiLineGenJnlDocZeroBalance(GenJournalBatch, GenJournalLine[1]);

        // [GIVEN] Create 6 line zero balance document DOC2  
        CreateMultiLineGenJnlDocZeroBalance(GenJournalBatch, GenJournalLine[2]);

        // [GIVEN] Create one more line for document DOC1
        CreateGenJournalLineWithDocumentNo(ExtraGenJournalLine[1], GenJournalBatch, GenJournalLine[1]."Document No.");
        // [GIVEN] Create one more line for document DOC2
        CreateGenJournalLineWithDocumentNo(ExtraGenJournalLine[2], GenJournalBatch, GenJournalLine[2]."Document No.");

        // [GIVEN] RunCheck to mock full batch check
        MockFullBatchCheck(
            GenJournalLine[1]."Journal Template Name",
            GenJournalLine[1]."Journal Batch Name",
            TempErrorMessage);

        // [THEN] Number of "out of balance" errors = 14
        Assert.AreEqual(GenJournalLine[1].Count() + GenJournalLine[2].Count(), TempErrorMessage.Count(), 'Invalid number of errors');

        // [GIVEN] Mock 2 extra lines deleted
        JournalErrorsMgt.InsertDeletedLine(ExtraGenJournalLine[1]);
        ExtraGenJournalLine[1].Delete();
        JournalErrorsMgt.InsertDeletedLine(ExtraGenJournalLine[2]);
        ExtraGenJournalLine[2].Delete();

        // [WHEN] Run CleanTempErrorMessages 
        SetErrorHandlingParameters(ErrorHandlingParameters, GenJournalLine[1], GenJournalLine[1]."Document No.", GenJournalLine[1]."Posting Date",
            GenJournalLine[1]."Document No.", GenJournalLine[1]."Posting Date", false, false);
        BackgroundErrorHandlingMgt.CleanTempErrorMessages(TempErrorMessage, ErrorHandlingParameters);

        // [THEN] Removed not only errors related to deleted lines but for documents DOC1 and DOC2 lines as well 
        Assert.AreEqual(0, TempErrorMessage.Count(), 'Invalid number of errors');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveToAnotherJournalLineWithoutModify()
    var
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        ErrorHandlingParameters: Record "Error Handling Parameters";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        ErrorsCount: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 355641] Errors are not deleted when user move from one line to another without modifying data
        Initialize();

        // [GIVEN] journal lines with empty amount: Line1 and Line2
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[1], GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            "Gen. Journal Document Type"::" ", "Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 0);

        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[2], GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            "Gen. Journal Document Type"::" ", "Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 0);

        // [GIVEN] Mock full batch check
        MockFullBatchCheck(
            GenJournalLine[1]."Journal Template Name",
            GenJournalLine[1]."Journal Batch Name",
            TempErrorMessage);
        TempErrorMessage.Reset();
        ErrorsCount := TempErrorMessage.Count();

        // [WHEN] Run CleanTempErrorMessages 
        SetErrorHandlingParameters(ErrorHandlingParameters, GenJournalLine[1], GenJournalLine[1]."Document No.", GenJournalLine[1]."Posting Date",
            GenJournalLine[1]."Document No.", GenJournalLine[1]."Posting Date", false, false);
        BackgroundErrorHandlingMgt.CleanTempErrorMessages(TempErrorMessage, ErrorHandlingParameters);

        // [THEN] Errors count left the same
        TempErrorMessage.Reset();
        Assert.AreEqual(ErrorsCount, TempErrorMessage.Count(), 'Errors count must be the same.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MissedDefaultDimensionErrors()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Dimension: array[2] of Record Dimension;
        TempErrorMessage: Record "Error Message" temporary;
        i: Integer;
    begin
        // [SCENARIO 364840] Several missed default dimensions found in background check
        Initialize();

        // [GIVEN] Create journal line with 2 mandatory default dimensions "DIM1" and "DIM2"
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            "Gen. Journal Document Type"::" ", "Gen. Journal Account Type"::"G/L Account",
            CreateGLAccountWithTwoMandatoryDefaultDim(Dimension), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Mock full batch check
        MockFullBatchCheck(
            GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            TempErrorMessage);

        // [THEN] Errors created for DIM1 and DIM2: "Select a Dimension Value Code for the Dimension Code ..."
        for i := 1 to 2 do begin
            TempErrorMessage.SetFilter(Description, StrSubstNo(DimErr, Dimension[1].Code, GenJournalLine."Account No."));
            Assert.IsTrue(TempErrorMessage.FindFirst(), 'Expected error not found');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalShowLinesWithErrorsActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Action "Show Lines with Errors" makes action "Show All Lines" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [WHEN] Action "Show Lines with Errors" is being selected
        GeneralJournal.ShowLinesWithErrors.Invoke();

        // [THEN] Action "Show Lines with Errors" disabled
        assert.IsFalse(GeneralJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be disabled');
        // [THEN] Action "Show All Lines" enabled
        assert.IsTrue(GeneralJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalShowAllLinesActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Action "Show All Lines" makes action "Show Lines with Errors" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);
        // [GIVEN] Action "Show Lines with Errors" is selected
        GeneralJournal.ShowLinesWithErrors.Invoke();

        // [WHEN] Action "Show All Lines" is being selected
        GeneralJournal.ShowAllLines.Invoke();

        // [THEN] Action "Show Lines with Errors" enabled
        assert.IsTrue(GeneralJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be enabled');
        // [THEN] Action "Show All Lines" disabled
        assert.IsFalse(GeneralJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashReceiptJournalShowLinesWithErrorsActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [SCENARIO 355641] Action "Show Lines with Errors" makes action "Show All Lines" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        CashReceiptJournal.Trap();
        Page.Run(Page::"Cash Receipt Journal", GenJournalLine);

        // [WHEN] Action "Show Lines with Errors" is being selected
        CashReceiptJournal.ShowLinesWithErrors.Invoke();

        // [THEN] Action "Show Lines with Errors" disabled
        assert.IsFalse(CashReceiptJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be disabled');
        // [THEN] Action "Show All Lines" enabled
        assert.IsTrue(CashReceiptJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashReceiptJournalShowAllLinesActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [SCENARIO 355641] Action "Show All Lines" makes action "Show Lines with Errors" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        CashReceiptJournal.Trap();
        Page.Run(Page::"Cash Receipt Journal", GenJournalLine);
        // [GIVEN] Action "Show Lines with Errors" is selected
        CashReceiptJournal.ShowLinesWithErrors.Invoke();

        // [WHEN] Action "Show All Lines" is being selected
        CashReceiptJournal.ShowAllLines.Invoke();

        // [THEN] Action "Show Lines with Errors" enabled
        assert.IsTrue(CashReceiptJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be enabled');
        // [THEN] Action "Show All Lines" disabled
        assert.IsFalse(CashReceiptJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedAssetGLJournalShowLinesWithErrorsActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FixedAssetGLJournal: TestPage "Fixed Asset G/L Journal";
    begin
        // [SCENARIO 355641] Action "Show Lines with Errors" makes action "Show All Lines" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        FixedAssetGLJournal.Trap();
        Page.Run(Page::"Fixed Asset G/L Journal", GenJournalLine);

        // [WHEN] Action "Show Lines with Errors" is being selected
        FixedAssetGLJournal.ShowLinesWithErrors.Invoke();

        // [THEN] Action "Show Lines with Errors" disabled
        assert.IsFalse(FixedAssetGLJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be disabled');
        // [THEN] Action "Show All Lines" enabled
        assert.IsTrue(FixedAssetGLJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedAssetGLJournalShowAllLinesActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FixedAssetGLJournal: TestPage "Fixed Asset G/L Journal";
    begin
        // [SCENARIO 355641] Action "Show All Lines" makes action "Show Lines with Errors" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        FixedAssetGLJournal.Trap();
        Page.Run(Page::"Fixed Asset G/L Journal", GenJournalLine);
        // [GIVEN] Action "Show Lines with Errors" is selected
        FixedAssetGLJournal.ShowLinesWithErrors.Invoke();

        // [WHEN] Action "Show All Lines" is being selected
        FixedAssetGLJournal.ShowAllLines.Invoke();

        // [THEN] Action "Show Lines with Errors" enabled
        assert.IsTrue(FixedAssetGLJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be enabled');
        // [THEN] Action "Show All Lines" disabled
        assert.IsFalse(FixedAssetGLJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICGeneralJournalShowLinesWithErrorsActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICGeneralJournal: TestPage "IC General Journal";
    begin
        // [SCENARIO 355641] Action "Show Lines with Errors" makes action "Show All Lines" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        ICGeneralJournal.Trap();
        Page.Run(Page::"IC General Journal", GenJournalLine);

        // [WHEN] Action "Show Lines with Errors" is being selected
        ICGeneralJournal.ShowLinesWithErrors.Invoke();

        // [THEN] Action "Show Lines with Errors" disabled
        assert.IsFalse(ICGeneralJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be disabled');
        // [THEN] Action "Show All Lines" enabled
        assert.IsTrue(ICGeneralJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICGeneralJournalShowAllLinesActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICGeneralJournal: TestPage "IC General Journal";
    begin
        // [SCENARIO 355641] Action "Show All Lines" makes action "Show Lines with Errors" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        ICGeneralJournal.Trap();
        Page.Run(Page::"IC General Journal", GenJournalLine);
        // [GIVEN] Action "Show Lines with Errors" is selected
        ICGeneralJournal.ShowLinesWithErrors.Invoke();

        // [WHEN] Action "Show All Lines" is being selected
        ICGeneralJournal.ShowAllLines.Invoke();

        // [THEN] Action "Show Lines with Errors" enabled
        assert.IsTrue(ICGeneralJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be enabled');
        // [THEN] Action "Show All Lines" disabled
        assert.IsFalse(ICGeneralJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobGLJournalShowLinesWithErrorsActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JobGLJournal: TestPage "Job G/L Journal";
    begin
        // [SCENARIO 355641] Action "Show Lines with Errors" makes action "Show All Lines" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        JobGLJournal.Trap();
        Page.Run(Page::"Job G/L Journal", GenJournalLine);

        // [WHEN] Action "Show Lines with Errors" is being selected
        JobGLJournal.ShowLinesWithErrors.Invoke();

        // [THEN] Action "Show Lines with Errors" disabled
        assert.IsFalse(JobGLJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be disabled');
        // [THEN] Action "Show All Lines" enabled
        assert.IsTrue(JobGLJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobGLJournalShowAllLinesActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JobGLJournal: TestPage "Job G/L Journal";
    begin
        // [SCENARIO 355641] Action "Show All Lines" makes action "Show Lines with Errors" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        JobGLJournal.Trap();
        Page.Run(Page::"Job G/L Journal", GenJournalLine);
        // [GIVEN] Action "Show Lines with Errors" is selected
        JobGLJournal.ShowLinesWithErrors.Invoke();

        // [WHEN] Action "Show All Lines" is being selected
        JobGLJournal.ShowAllLines.Invoke();

        // [THEN] Action "Show Lines with Errors" enabled
        assert.IsTrue(JobGLJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be enabled');
        // [THEN] Action "Show All Lines" disabled
        assert.IsFalse(JobGLJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentJournalShowLinesWithErrorsActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 355641] Action "Show Lines with Errors" makes action "Show All Lines" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        PaymentJournal.Trap();
        Page.Run(Page::"Payment Journal", GenJournalLine);

        // [WHEN] Action "Show Lines with Errors" is being selected
        PaymentJournal.ShowLinesWithErrors.Invoke();

        // [THEN] Action "Show Lines with Errors" disabled
        assert.IsFalse(PaymentJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be disabled');
        // [THEN] Action "Show All Lines" enabled
        assert.IsTrue(PaymentJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentJournalShowAllLinesActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 355641] Action "Show All Lines" makes action "Show Lines with Errors" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        PaymentJournal.Trap();
        Page.Run(Page::"Payment Journal", GenJournalLine);
        // [GIVEN] Action "Show Lines with Errors" is selected
        PaymentJournal.ShowLinesWithErrors.Invoke();

        // [WHEN] Action "Show All Lines" is being selected
        PaymentJournal.ShowAllLines.Invoke();

        // [THEN] Action "Show Lines with Errors" enabled
        assert.IsTrue(PaymentJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be enabled');
        // [THEN] Action "Show All Lines" disabled
        assert.IsFalse(PaymentJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseJournalShowLinesWithErrorsActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [SCENARIO 355641] Action "Show Lines with Errors" makes action "Show All Lines" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        PurchaseJournal.Trap();
        Page.Run(Page::"Purchase Journal", GenJournalLine);

        // [WHEN] Action "Show Lines with Errors" is being selected
        PurchaseJournal.ShowLinesWithErrors.Invoke();

        // [THEN] Action "Show Lines with Errors" disabled
        assert.IsFalse(PurchaseJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be disabled');
        // [THEN] Action "Show All Lines" enabled
        assert.IsTrue(PurchaseJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseJournalShowAllLinesActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [SCENARIO 355641] Action "Show All Lines" makes action "Show Lines with Errors" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        PurchaseJournal.Trap();
        Page.Run(Page::"Purchase Journal", GenJournalLine);
        // [GIVEN] Action "Show Lines with Errors" is selected
        PurchaseJournal.ShowLinesWithErrors.Invoke();

        // [WHEN] Action "Show All Lines" is being selected
        PurchaseJournal.ShowAllLines.Invoke();

        // [THEN] Action "Show Lines with Errors" enabled
        assert.IsTrue(PurchaseJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be enabled');
        // [THEN] Action "Show All Lines" disabled
        assert.IsFalse(PurchaseJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesJournalShowLinesWithErrorsActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [SCENARIO 355641] Action "Show Lines with Errors" makes action "Show All Lines" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        SalesJournal.Trap();
        Page.Run(Page::"Sales Journal", GenJournalLine);

        // [WHEN] Action "Show Lines with Errors" is being selected
        SalesJournal.ShowLinesWithErrors.Invoke();

        // [THEN] Action "Show Lines with Errors" disabled
        assert.IsFalse(SalesJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be disabled');
        // [THEN] Action "Show All Lines" enabled
        assert.IsTrue(SalesJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesJournalShowAllLinesActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [SCENARIO 355641] Action "Show All Lines" makes action "Show Lines with Errors" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        SalesJournal.Trap();
        Page.Run(Page::"Sales Journal", GenJournalLine);
        // [GIVEN] Action "Show Lines with Errors" is selected
        SalesJournal.ShowLinesWithErrors.Invoke();

        // [WHEN] Action "Show All Lines" is being selected
        SalesJournal.ShowAllLines.Invoke();

        // [THEN] Action "Show Lines with Errors" enabled
        assert.IsTrue(SalesJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be enabled');
        // [THEN] Action "Show All Lines" disabled
        assert.IsFalse(SalesJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlCheckLineOnBeforeRunCheck()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        ERMGenJnlErrorHandling: Codeunit "ERM Gen. Jnl. Error Handling";
    begin
        // [SCENARIO 367332] Changes made by event OnBeforeRunCheck has effect on error handling
        Initialize();

        // [GIVEN] Create journal line 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Mark journal line for OnBeforeRunCheck event
        GenJournalLine.Description := OnBeforeRunCheckTxt;
        GenJournalLine.Modify();
        // [GIVEN] Subscribe on OnBeforeRunCheck and set Amount = 0 (see OnBeforeRunCheck sibscriber)
        BindSubscription(ERMGenJnlErrorHandling);

        // [WHEN] Mock run codeunit "Gen. Jnl.-Check Line" with LogErrorMode=True
        MockGenJnlCheckLineRun(GenJournalLine, TempErrorMessage);

        // [THEN] Error message "Amount must not be empty"
        TempErrorMessage.TestField("Context Record ID", GenJournalLine.RecordId());
        TempErrorMessage.TestField(Description, StrSubstNo(TestFieldEmptyValueErr, GenJournalLine.FieldCaption(Amount)));

        UnBindSubscription(ERMGenJnlErrorHandling);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDeletedDocumentsFromArgsUT()
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        TempResultGenJnlLine: Record "Gen. Journal Line" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        Args: Dictionary of [Text, Text];
        i: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 367332] Unit test for function GetDeletedDocumentsFromArgs
        Initialize();

        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        // [GIVEN] Mock 3 jounrnal document lines with different "Document No." and "Posing Date" deleted
        for i := 1 to LibraryRandom.RandIntInRange(5, 10) do
            MockDummyJournalDocumentLineDeleted(GenJournalBatch, TempGenJnlLine);

        // [GIVEN] Pack buffer to Args
        BackgroundErrorHandlingMgt.PackDeletedDocumentsToArgs(Args);

        // [WHEN] Function GetDeletedDocumentsFromArgs is being run
        BackgroundErrorHandlingMgt.GetDeletedDocumentsFromArgs(Args, TempResultGenJnlLine);

        // [THEN] Buffer contains all 3 documents
        Assert.AreEqual(TempGenJnlLine.Count, TempResultGenJnlLine.Count, 'Number of buffer records must be the same');
        TempGenJnlLine.FindSet();
        TempResultGenJnlLine.FindSet();
        repeat
            TempResultGenJnlLine.TestField("Document No.", TempGenJnlLine."Document No.");
            TempResultGenJnlLine.TestField("Posting Date", TempGenJnlLine."Posting Date");

            TempResultGenJnlLine.Next();
        until TempGenJnlLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetRecXRecOnModifyRunTwice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        xGenJournalLine: Record "Gen. Journal Line";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 385781] No error in case of subsequent call of SetRecXRecOnModify for same general journal record
        Initialize();

        // [GIVEN] Prepare Rec and xRec parameters for SetRecXRecOnModify
        CreateGenJournalLine(xGenJournalLine);
        GenJournalLine := xGenJournalLine;
        GenJournalLine.Description := OnBeforeRunCheckTxt;
        GenJournalLine.Modify();

        // [GIVEN] Run SetRecXRecOnModify
        JournalErrorsMgt.SetRecXRecOnModify(GenJournalLine, xGenJournalLine);
        // [WHEN] Run SetRecXRecOnModify with same parameters second time
        JournalErrorsMgt.SetRecXRecOnModify(GenJournalLine, xGenJournalLine);

        // [THEN] No error "Gen. Journal Line already exists"
        Assert.IsTrue(JournalErrorsMgt.GetRecXRecOnModify(GenJournalLine, xGenJournalLine), 'GetRecXRecOnModify failed');
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        Commit(); // need to notify background sessions about data restore
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        IsInitialized := true;
    end;

    procedure EnableFeature()
    begin
        BackgroundErrorCheckFeatureEnabled := true;
    end;

    local procedure EnableFeature(var ERMGenJnlErrorHandling: codeunit "ERM Gen. Jnl. Error Handling")
    begin
        BindSubscription(ERMGenJnlErrorHandling);
        ERMGenJnlErrorHandling.EnableFeature();
    end;

    local procedure ClearAmountAndDocumentNo(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate(Amount, 0);
        GenJournalLine."Document No." := '';
        GenJournalLine.Modify();
    end;

    local procedure MockDummyJournalDocumentLineDeleted(GenJournalBatch: Record "Gen. Journal Batch"; var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    var
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
    begin
        if TempGenJnlLine.FindLast() then;
        TempGenJnlLine."Line No." := TempGenJnlLine."Line No." + 1;
        TempGenJnlLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        TempGenJnlLine."Journal Batch Name" := GenJournalBatch.Name;
        TempGenJnlLine."Posting Date" := LibraryRandom.RandDate(100);
        TempGenJnlLine."Document No." := LibraryRandom.RandText(MaxStrLen(TempGenJnlLine."Document No."));
        TempGenJnlLine.Insert();

        JournalErrorsMgt.InsertDeletedLine(TempGenJnlLine);
    end;

    local procedure CreateGLAccountWithTwoMandatoryDefaultDim(var Dimension: array[2] of Record Dimension) GLAccountNo: Code[20]
    var
        DefaultDimension: Record "Default Dimension";
        i: Integer;
    begin
        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();

        for i := 1 to 2 do begin
            LibraryDimension.CreateDimension(Dimension[i]);
            LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccountNo, Dimension[i].Code, '');
            DefaultDimension."Value Posting" := DefaultDimension."Value Posting"::"Code Mandatory";
            DefaultDimension.Modify();
        end;
    end;

    local procedure CreateMultiLineGenJnlDocOutOfBalance(var GenJournalLine: Record "Gen. Journal Line"; var TotalBalance: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        i: Integer;
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);

        for i := 1 to LibraryRandom.RandIntInRange(5, 10) do begin
            LibraryERM.CreateGeneralJnlLine2WithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name",
              GenJournalBatch.Name, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
              LibraryERM.CreateGLAccountNoWithDirectPosting(), GenJournalLine."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
            TotalBalance += GenJournalLine.Amount;
        end;
    end;

    local procedure CreateMultiLineGenJnlDocZeroBalance(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        TotalBalance: Decimal;
        i: Integer;
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);

        for i := 1 to LibraryRandom.RandIntInRange(5, 10) do begin
            LibraryERM.CreateGeneralJnlLine2WithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name",
              GenJournalBatch.Name, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
              LibraryERM.CreateGLAccountNoWithDirectPosting(), GenJournalLine."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
            TotalBalance += GenJournalLine.Amount;
        end;
        LibraryERM.CreateGeneralJnlLine2WithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNoWithDirectPosting(), GenJournalLine."Bal. Account Type"::"G/L Account", '', -TotalBalance);
    end;

    local procedure CreateMultiLineGenJnlDocZeroBalance(GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    var
        TotalBalance: Decimal;
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandIntInRange(5, 10) do begin
            LibraryERM.CreateGeneralJnlLine2WithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name",
              GenJournalBatch.Name, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
              LibraryERM.CreateGLAccountNoWithDirectPosting(), GenJournalLine."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
            TotalBalance += GenJournalLine.Amount;
        end;
        LibraryERM.CreateGeneralJnlLine2WithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNoWithDirectPosting(), GenJournalLine."Bal. Account Type"::"G/L Account", '', -TotalBalance);

        GenJournalLine.SetRange("Document No.", GenJournalLine."Document No.");
    end;

    local procedure CreateZeroAmountJournalLines(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        i: Integer;
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);

        for i := 1 to LibraryRandom.RandIntInRange(5, 10) do begin
            LibraryERM.CreateGeneralJnlLine2WithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name",
              GenJournalBatch.Name, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
              LibraryERM.CreateGLAccountNoWithDirectPosting(), GenJournalLine."Bal. Account Type"::"G/L Account", '', 0);
        end;
    end;

    local procedure CreateEmptyDocGenJournalLineForTemplate(var GenJournalLine: Record "Gen. Journal Line"; TemplateType: Enum "Gen. Journal Template Type"; PageId: Integer)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalTemplateBatch(GenJournalBatch, TemplateType, PageId);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            "Gen. Journal Document Type"::" ", "Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
        GenJournalLine."Document No." := '';
        GenJournalLine.Modify();
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateGenJournalLines(GenJournalLine, 1);
    end;

    local procedure CreateGenJournalLines(var GenJournalLine: Record "Gen. Journal Line"; NumbefOfLines: Integer)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        i: Integer;
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalBatch.Modify();

        for i := 1 to NumbefOfLines do
            LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
                "Gen. Journal Document Type"::" ", "Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateGenJournalLineWithDocumentNo(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine2WithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNoWithDirectPosting(), GenJournalLine."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
        GenJournalLine."Document No." := DocumentNo;
        GenJournalLine.Modify();
    end;

    local procedure CreateGenJournalTemplateBatch(var GenJournalTemplate: Record "Gen. Journal Template"; var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Background Error Check" := true;
        GenJournalBatch.Modify();
    end;

    local procedure CreateGenJournalTemplateBatch(var GenJournalBatch: Record "Gen. Journal Batch"; TemplateType: Enum "Gen. Journal Template Type"; PageID: Integer)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, TemplateType);
        GenJournalTemplate.Get(GenJournalBatch."Journal Template Name");
        GenJournalTemplate.Validate("Page ID", PageID);
        GenJournalTemplate.Modify();

        GenJournalBatch."Background Error Check" := true;
        GenJournalBatch.Modify();
    end;

    local procedure GetNumberOfLines(var GenJournalLine: Record "Gen. Journal Line"): Integer
    begin
        SetBatchFilter(GenJournalLine);
        exit(GenJournalLine.Count());
    end;

    local procedure MockLineModified(xGenJournalLine: Record "Gen. Journal Line"; GenJournalLine: Record "Gen. Journal Line"; var TempErrorMessage: Record "Error Message" temporary)
    var
        ErrorHandlingParameters: Record "Error Handling Parameters";
        CheckGenJnlLineBackgr: Codeunit "Check Gen. Jnl. Line. Backgr.";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        Params: Dictionary of [Text, Text];
    begin
        ClearTempErrorMessage(TempErrorMessage);
        SetErrorHandlingParameters(ErrorHandlingParameters,
            GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
            GenJournalLine."Document No.", GenJournalLine."Posting Date",
            xGenJournalLine."Document No.", xGenJournalLine."Posting Date", false, true);
        ErrorHandlingParameters.ToArgs(Params);

        JournalErrorsMgt.SetRecXRecOnModify(xGenJournalLine, GenJournalLine);
        Commit();
        CheckGenJnlLineBackgr.RunCheck(Params, TempErrorMessage);
    end;

    local procedure MockFullBatchCheck(TemplateName: Code[10]; BatchName: Code[10]; var TempErrorMessage: Record "Error Message" temporary)
    var
        ErrorHandlingParameters: Record "Error Handling Parameters";
        CheckGenJnlLineBackgr: Codeunit "Check Gen. Jnl. Line. Backgr.";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        Params: Dictionary of [Text, Text];
    begin
        ClearTempErrorMessage(TempErrorMessage);

        SetErrorHandlingParameters(ErrorHandlingParameters, TemplateName, BatchName, '', 0D, '', 0D, true, false);
        ErrorHandlingParameters.ToArgs(Params);
        Commit();
        CheckGenJnlLineBackgr.RunCheck(Params, TempErrorMessage);
    end;

    local procedure MockGenJnlCheckLineRun(var GenJournalLine: Record "Gen. Journal Line"; var TempErrorMessage: Record "Error Message" temporary)
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        GenJnlCheckLine.SetLogErrorMode(true);
        GenJnlCheckLine.Run(GenJournalLine);
        GenJnlCheckLine.GetErrors(TempErrorMessage);
    end;

    local procedure SetErrorHandlingParameters(var ErrorHandlingParameters: Record "Error Handling Parameters"; TemplateName: Code[10]; BatchName: Code[10]; DocumentNo: Code[20]; PostingDate: Date; xDocumentNo: Code[20]; xPostingDate: Date; FullBatchCheck: Boolean; LineModified: Boolean)
    begin
        ErrorHandlingParameters.Init();
        ErrorHandlingParameters."Journal Template Name" := TemplateName;
        ErrorHandlingParameters."Journal Batch Name" := BatchName;
        ErrorHandlingParameters."Document No." := DocumentNo;
        ErrorHandlingParameters."Posting Date" := PostingDate;
        ErrorHandlingParameters."Previous Document No." := xDocumentNo;
        ErrorHandlingParameters."Previous Posting Date" := xPostingDate;
        ErrorHandlingParameters."Full Batch Check" := FullBatchCheck;
        ErrorHandlingParameters."Line Modified" := LineModified;
    end;

    local procedure ClearTempErrorMessage(var TempErrorMessage: Record "Error Message" temporary)
    begin
        TempErrorMessage.Reset();
        TempErrorMessage.DeleteAll();
    end;

    local procedure SetBatchFilter(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
    end;

    local procedure SetErrorHandlingParameters(var ErrorHandlingParameters: Record "Error Handling Parameters"; GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; PostingDate: Date; xDocumentNo: Code[20]; xPostingDate: Date; FullBatchCheck: Boolean; LineModified: Boolean)
    begin
        ErrorHandlingParameters.Init();
        ErrorHandlingParameters."Journal Template Name" := GenJournalLine."Journal Template Name";
        ErrorHandlingParameters."Journal Batch Name" := GenJournalLine."Journal Batch Name";
        ErrorHandlingParameters."Document No." := DocumentNo;
        ErrorHandlingParameters."Posting Date" := PostingDate;
        ErrorHandlingParameters."Previous Document No." := xDocumentNo;
        ErrorHandlingParameters."Previous Posting Date" := xPostingDate;
        ErrorHandlingParameters."Full Batch Check" := FullBatchCheck;
        ErrorHandlingParameters."Line Modified" := LineModified;
    end;

    [EventSubscriber(ObjectType::Codeunit, 11, 'OnAfterCheckGenJnlLine', '', false, false)]
    local procedure OnAfterCheckGenJnlLineExtendingGenJnlCheckLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        if GenJournalLine.Description = ExtendingGenJnlCheckLineTxt then
            ErrorMessageMgt.LogError(GenJournalLine, DummyErr, '');
    end;

    [EventSubscriber(ObjectType::Codeunit, 11, 'OnAfterCheckGenJnlLine', '', false, false)]
    local procedure OnAfterCheckGenJnlLineLogTestFieldOption(var GenJournalLine: Record "Gen. Journal Line")
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
        RecRef: RecordRef;
    begin
        if GenJournalLine.Description = LogTestFieldOptionTxt then begin
            GenJournalLine."IC Direction" := GenJournalLine."IC Direction"::Incoming;
            RecRef.GetTable(GenJournalLine);
            ErrorMessageMgt.LogTestField(RecRef, GenJournalLine.FieldNo("IC Direction"), GenJournalLine."IC Direction"::Outgoing);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 11, 'OnBeforeRunCheck', '', false, false)]
    local procedure OnBeforeRunCheck(var GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine.Description = OnBeforeRunCheckTxt then
            GenJournalLine.Validate(Amount, 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Journal Errors Mgt.", 'OnAfterIsEnabled', '', false, false)]
    local procedure OnAfterIsEnabled(var Result: Boolean);
    begin
        Result := BackgroundErrorCheckFeatureEnabled;
    end;
}