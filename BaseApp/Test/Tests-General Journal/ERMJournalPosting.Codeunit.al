codeunit 134420 "ERM Journal Posting"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [General Journal]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;
        MinRange: Decimal;
        MiddleRange: Decimal;
        MaxRange: Decimal;

    [Test]
    [Scope('OnPrem')]
    procedure PostOneGenJnLineWithQty()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        Qty: Decimal;
        PostedQty: Decimal;
    begin
        Initialize();
        Qty := LibraryRandom.RandDecInRange(MinRange, MaxRange, 2);
        CreateGenJournalBatch(GenJournalBatch);
        FindGLAccount(GLAccount, false);
        PostedQty := CreateAndPostGenJrnLine(GenJournalBatch, GLAccount, Qty);

        Assert.AreEqual(
          Qty, PostedQty, 'The Quantity on Entry must match the Quantity on the Journal');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeTestForPostOneGenJnLineWithQty()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        Qty: Decimal;
        PostedQty: Decimal;
    begin
        Initialize();
        Qty := LibraryRandom.RandDecInRange(MinRange, MiddleRange, 2);
        CreateGenJournalBatch(GenJournalBatch);
        FindGLAccount(GLAccount, false);
        PostedQty := CreateAndPostGenJrnLine(GenJournalBatch, GLAccount, Qty);

        Assert.AreNotEqual(
          LibraryRandom.RandDecInRange(MiddleRange, MaxRange, 2), PostedQty,
          'The Quantity on Entry must match the Quantity on the Journal');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOneGenJnLineWithoutQty()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        Qty: Decimal;
        PostedQty: Decimal;
    begin
        Initialize();
        Qty := 0;
        CreateGenJournalBatch(GenJournalBatch);
        FindGLAccount(GLAccount, false);
        PostedQty := CreateAndPostGenJrnLine(GenJournalBatch, GLAccount, Qty);

        Assert.AreEqual(Qty, PostedQty, 'The Quantity on Entry must match the Quantity on the Journal');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyOmitDescOnJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccountOmitDesc: Record "G/L Account";
        GLAccountWithDesc: Record "G/L Account";
    begin
        Initialize();
        CreateGenJournalBatch(GenJournalBatch);
        FindGLAccount(GLAccountOmitDesc, true);

        LibraryLowerPermissions.SetJournalsEdit;
        CreateGenJrnLine(GenJournalLine, GenJournalBatch, GLAccountOmitDesc);
        Assert.IsTrue(DelChr(GenJournalLine.Description, '=', ' ') = '', 'Description must be blank');
        LibraryLowerPermissions.SetO365Setup();

        FindGLAccount(GLAccountWithDesc, false);
        LibraryLowerPermissions.SetJournalsEdit;
        CreateGenJrnLine(GenJournalLine, GenJournalBatch, GLAccountWithDesc);
        Assert.IsFalse(DelChr(GenJournalLine.Description, '=', ' ') = '', 'Description must not be blank');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlPostBatchResetsAutoCalcFields()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMJournalPosting: Codeunit "ERM Journal Posting";
    begin
        // [FEATURE] [UT] [Batch] [Performance]
        // [SCENARIO 301026] COD 13 "Gen. Jnl.-Post Batch" resets auto calc fields
        Initialize();

        // [GIVEN] General Journal Line with enabled auto calc fields for "Has Payment Export Error" field
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account", '', 0);
        GenJournalLine.SetAutoCalcFields("Has Payment Export Error");
        // [GIVEN] Linked "Payment Jnl. Export Error Text" record
        MockPmtExportErr(GenJournalLine);
        // [GIVEN] Ensure "General Journal Line"."Has Payment Export Error" = TRUE after FIND
        GenJournalLine.Find();
        GenJournalLine.TestField("Has Payment Export Error", true);

        // [WHEN] Perform COD 13 "Gen. Jnl.-Post Batch".RUN()
        BindSubscription(ERMJournalPosting);
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);

        // [THEN] Auto calc field is reset within COD13: "Has Payment Export Error" = FALSE after FIND
        // See [EventSubscriber] OnBeforeCode
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlPostBatchResetsAutoCalcFieldsOnPreview()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        ERMJournalPosting: Codeunit "ERM Journal Posting";
    begin
        // [FEATURE] [UT] [Batch] [Performance] [Preview]
        // [SCENARIO 301026] COD 13 "Gen. Jnl.-Post Batch" resets auto calc fields in case of Preview posting
        Initialize();

        // [GIVEN] General Journal Line with enabled auto calc fields for "Has Payment Export Error" field
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account", '', 0);
        GenJournalLine.SetAutoCalcFields("Has Payment Export Error");
        // [GIVEN] Linked "Payment Jnl. Export Error Text" record
        MockPmtExportErr(GenJournalLine);
        // [GIVEN] Ensure "General Journal Line"."Has Payment Export Error" = TRUE after FIND
        GenJournalLine.Find();
        GenJournalLine.TestField("Has Payment Export Error", true);

        // [WHEN] Perform COD 13 "Gen. Jnl.-Post Batch".Preview()
        BindSubscription(ERMJournalPosting);
        asserterror GenJnlPostBatch.Preview(GenJournalLine);
        Assert.ExpectedError('Preview mode.');

        // [THEN] Auto calc field is reset within COD13: "Has Payment Export Error" = FALSE after FIND
        // See [EventSubscriber] OnBeforeCode
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetPostAndPrintWithJobQueueGeneralLedgerSetupUT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [Setup] [UT]
        // [SCENARIO ] "Post with Job Queue" is TRUE when "Post & Print with Job Queue" enabled
        Initialize();

        // [GIVEN] Setup, "Post with Job Queue" = FALSE, "Post & Print with Job Queue" = FALSE
        LibraryJournals.SetPostWithJobQueue(false);
        LibraryJournals.SetPostAndPrintWithJobQueue(false);
        GeneralLedgerSetup.Get();
        // [WHEN] Set "Post & Print with Job Queue" = TRUE
        GeneralLedgerSetup.Validate("Post & Print with Job Queue", true);
        // [THEN] "Post with Job Queue" = TRUE
        Assert.IsTrue(GeneralLedgerSetup."Post with Job Queue", 'Setup is not correct.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResetPostWithJobQueueGeneralLedgerSetupUT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [Setup] [UT]
        // [SCENARIO ] "Post & Print with Job Queue" is FALSE when "Post with Job Queue" is disabled
        Initialize();

        // [GIVEN] Setup, "Post with Job Queue" = TRUE, "Post & Print with Job Queue" = TRUE
        LibraryJournals.SetPostWithJobQueue(true);
        LibraryJournals.SetPostAndPrintWithJobQueue(true);
        GeneralLedgerSetup.Get();
        // [WHEN] Set "Post with Job Queue" = FALSE
        GeneralLedgerSetup.Validate("Post with Job Queue", false);
        // [THEN] "Post & Print with Job Queue" = FALSE
        Assert.IsFalse(GeneralLedgerSetup."Post & Print with Job Queue", 'Setup is not correct.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetPrintReportOutputTypeInSaaSGeneralLedgerSetupUT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [FEATURE] [Setup] [UT]
        // [SCENARIO ] Set "Report Output Type" = Print in SaaS
        Initialize();

        // [GIVEN] SaaS, Setup
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        GeneralLedgerSetup.Get();
        // [WHEN] Set "Report Output Type" = Print
        ASSERTERROR GeneralLedgerSetup.Validate("Report Output Type", GeneralLedgerSetup."Report Output Type"::Print);
        // [THEN] Error, "Report Output Type" must be PDF
        Assert.ExpectedError('Report Output Type must be equal to ''PDF''  in General Ledger Setup');
    end;

    [Test]
    procedure RecordLinkDeletedAfterPostingGenJnlLine()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        RecordLink: Record "Record Link";
    begin
        // [FEATURE] [Record Link] 
        // [SCENARIO] Record links are deleted after posting a general journal line

        Initialize();

        // [GIVEN] General journal line
        LibraryJournals.CreateGenJournalBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::" ",
            GenJnlLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
            GenJnlLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(1000, 2));

        // [GIVEN] Assign a record link to the journal line
        LibraryUtility.CreateRecordLink(GenJnlLine);

        // [WHEN] Post the journal
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [THEN] The record link is deleted
        RecordLink.SetRange("Record ID", GenJnlLine.RecordId);
        Assert.RecordIsEmpty(RecordLink);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Journal Posting");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Journal Posting");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        MinRange := 0;
        MiddleRange := 100;
        MaxRange := 200;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Journal Posting");
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure CreateAndPostGenJrnLine(GenJournalBatch: Record "Gen. Journal Batch"; GLAccount: Record "G/L Account"; Qty: Decimal): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
    begin
        GenJournalLine.Init();
        CreateGenJrnLine(GenJournalLine, GenJournalBatch, GLAccount);
        LibraryLowerPermissions.SetJournalsPost;
        GenJournalLine.Validate(Quantity, Qty);
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.FindLast();
        exit(GLEntry.Quantity);
    end;

    local procedure CreateGenJrnLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; GLAccount: Record "G/L Account")
    begin
        GenJournalLine.Init();
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          GenJournalLine."Document Type",
          GenJournalLine."Account Type",
          GLAccount."No.",
          0);

        GenJournalLine.Validate("Posting Date", CalcDate('<+3Y>', Today));
        GenJournalLine.Validate(Amount, LibraryRandom.RandDecInRange(MinRange, MaxRange, 2));
        GenJournalLine.Modify(true);
    end;

    local procedure MockPmtExportErr(GenJournalLine: Record "Gen. Journal Line")
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        with PaymentJnlExportErrorText do begin
            Init();
            "Journal Template Name" := GenJournalLine."Journal Template Name";
            "Journal Batch Name" := GenJournalLine."Journal Batch Name";
            "Journal Line No." := GenJournalLine."Line No.";
            Insert();
        end;
    end;

    local procedure FindGLAccount(var GLAccount: Record "G/L Account"; OmitDesc: Boolean)
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Name := 'Not Blank';
        GLAccount."Omit Default Descr. in Jnl." := OmitDesc;
        GLAccount.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", 'OnBeforeCode', '', false, false)]
    local procedure OnBeforeCode(var GenJournalLine: Record "Gen. Journal Line"; PreviewMode: Boolean; CommitIsSuppressed: Boolean)
    begin
        // Verify auto calc field is reset
        GenJournalLine.TestField("Has Payment Export Error", true);
        GenJournalLine.Find();
        GenJournalLine.TestField("Has Payment Export Error", false);
    end;
}

