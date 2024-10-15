#if not CLEAN22
codeunit 144007 "ERM Apply GL Entry"
{
    // 1: Verify error message while reversing GL Register with applied GL Entries.
    // 2: Verify GL Register successfully reversed when GL Entries are not applied.
    // 
    // Covers Test Cases:  344446
    // ---------------------------------------------------------------------------------------------------
    // Test Function Name                                                                           TFS ID
    // ---------------------------------------------------------------------------------------------------
    // ReverseEntryErrorWhileReversingGLRegisters, ReverseTransactionAfterPostGeneralJournal        169647

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Apply G/L Entry]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        RegisterErr: Label 'You cannot reverse Register No. %1 because the entry is either applied to an entry or has been changed by a batch job';
        NextLetterErr: Label 'Unexpected Next Letter.';
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [HandlerFunctions('ApplyGLEntriesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseEntryErrorWhileReversingGLRegisters()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLRegisters: TestPage "G/L Registers";
    begin
        // Verify error message while reversing GL Register containing applied GL Entries.

        // Setup.
        CreateAndPostGeneralJournalLines(GenJournalLine);
        ApplyGLEntries(GenJournalLine."Bal. Account No.");
        OpenGLRegistersPage(GLRegisters);

        // Exercise.
        asserterror GLRegisters.ReverseRegister.Invoke;

        // Verify: Verify error message.
        Assert.ExpectedError(StrSubstNo(RegisterErr, GLRegisters."No.".Value));
    end;

    [Test]
    [HandlerFunctions('ReverseEntriesModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseTransactionAfterPostGeneralJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLRegisters: TestPage "G/L Registers";
    begin
        // Verify GL Register successfully reversed when GL Entries are not applied.

        // Setup.
        CreateAndPostGeneralJournalLines(GenJournalLine);
        OpenGLRegistersPage(GLRegisters);

        // Exercise.
        GLRegisters.ReverseRegister.Invoke;  // Invokes ReverseEntriesModalPageHandler.

        // Verify: Verify Reversed Entries after Reverse Register on General ledger Entries.
        VerifyReversedEntries(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextLetterWhileApplyingGLEntriesFirstLetter()
    var
        GLEntryApplication: Codeunit "G/L Entry Application";
        Letter: Text[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255421] Function retrieving next Letter for G/L Entries returns 'AAA' if an empty Letter was passed.

        // [GIVEN] Empty Letter.
        Letter := '';

        // [WHEN] Get next Letter.
        GLEntryApplication.NextLetter(Letter);

        // [THEN] New Letter = 'AAA'.
        Assert.AreEqual('AAA', Letter, NextLetterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextLetterWhileApplyingGLEntriesAAA()
    var
        GLEntryApplication: Codeunit "G/L Entry Application";
        Letter: Text[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255421] Function retrieving next Letter for G/L Entries returns 'AAB' if previous Letter = 'AAA'.

        // [GIVEN] Previous Letter = 'AAA'.
        Letter := 'AAA';

        // [WHEN] Get next Letter.
        GLEntryApplication.NextLetter(Letter);

        // [THEN] New Letter = 'AAB'.
        Assert.AreEqual('AAB', Letter, NextLetterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextLetterWhileApplyingGLEntriesAZZ()
    var
        GLEntryApplication: Codeunit "G/L Entry Application";
        Letter: Text[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255421] Function retrieving next Letter for G/L Entries returns 'BAA' if previous Letter = 'AZZ'.

        // [GIVEN] Previous Letter = 'AZZ'.
        Letter := 'AZZ';

        // [WHEN] Get next Letter.
        GLEntryApplication.NextLetter(Letter);

        // [THEN] New Letter = 'BAA'.
        Assert.AreEqual('BAA', Letter, NextLetterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextLetterWhileApplyingGLEntriesZZZ()
    var
        GLEntryApplication: Codeunit "G/L Entry Application";
        Letter: Text[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255421] Function retrieving next Letter for G/L Entries returns 'ZZZ.000000' if previous Letter = 'ZZZ'.

        // [GIVEN] Previous Letter = 'ZZZ'.
        Letter := 'ZZZ';

        // [WHEN] Get next Letter.
        GLEntryApplication.NextLetter(Letter);

        // [THEN] New Letter = 'ZZZ.000000'.
        Assert.AreEqual('ZZZ.000000', Letter, NextLetterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextLetterWhileApplyingGLEntriesZZZ000000()
    var
        GLEntryApplication: Codeunit "G/L Entry Application";
        Letter: Text[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255421] Function retrieving next Letter for G/L Entries returns 'ZZZ.000001' if previous Letter = 'ZZZ.000000'.

        // [GIVEN] Previous Letter = 'ZZZ.000000'.
        Letter := 'ZZZ.000000';

        // [WHEN] Get next Letter.
        GLEntryApplication.NextLetter(Letter);

        // [THEN] New Letter = 'ZZZ.000001'.
        Assert.AreEqual('ZZZ.000001', Letter, NextLetterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextLetterWhileApplyingGLEntriesZZZ099999()
    var
        GLEntryApplication: Codeunit "G/L Entry Application";
        Letter: Text[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255421] Function retrieving next Letter for G/L Entries returns 'ZZZ.100000' if previous Letter = 'ZZZ.099999'.

        // [GIVEN] Previous Letter = 'ZZZ.099999'.
        Letter := 'ZZZ.099999';

        // [WHEN] Get next Letter.
        GLEntryApplication.NextLetter(Letter);

        // [THEN] New Letter = 'ZZZ.100000'.
        Assert.AreEqual('ZZZ.100000', Letter, NextLetterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextLetterWhileApplyingGLEntriesZZZ999999()
    var
        GLEntryApplication: Codeunit "G/L Entry Application";
        Letter: Text[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255421] Function retrieving next Letter for G/L Entries returns 'ZZZ.AAAAAA' if previous Letter = 'ZZZ.999999'.

        // [GIVEN] Previous Letter = 'ZZZ.999999'.
        Letter := 'ZZZ.999999';

        // [WHEN] Get next Letter.
        GLEntryApplication.NextLetter(Letter);

        // [THEN] New Letter = 'ZZZ.AAAAAA'.
        Assert.AreEqual('ZZZ.AAAAAA', Letter, NextLetterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextLetterWhileApplyingGLEntriesZZZAAAAAA()
    var
        GLEntryApplication: Codeunit "G/L Entry Application";
        Letter: Text[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255421] Function retrieving next Letter for G/L Entries returns 'ZZZ.AAAAAB' if previous Letter = 'ZZZ.AAAAAA'.

        // [GIVEN] Previous Letter = 'ZZZ.AAAAAA'.
        Letter := 'ZZZ.AAAAAA';

        // [WHEN] Get next Letter.
        GLEntryApplication.NextLetter(Letter);

        // [THEN] New Letter = 'ZZZ.AAAAAB'.
        Assert.AreEqual('ZZZ.AAAAAB', Letter, NextLetterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextLetterWhileApplyingGLEntriesZZZAZZZZZ()
    var
        GLEntryApplication: Codeunit "G/L Entry Application";
        Letter: Text[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255421] Function retrieving next Letter for G/L Entries returns 'ZZZ.BAAAAA' if previous Letter = 'ZZZ.AZZZZZ'.

        // [GIVEN] Previous Letter = 'ZZZ.AZZZZZ'.
        Letter := 'ZZZ.AZZZZZ';

        // [WHEN] Get next Letter.
        GLEntryApplication.NextLetter(Letter);

        // [THEN] New Letter = 'ZZZ.BAAAAA'.
        Assert.AreEqual('ZZZ.BAAAAA', Letter, NextLetterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNextLetterWhileApplyingGLEntriesLastLetter()
    var
        GLEntryApplication: Codeunit "G/L Entry Application";
        Letter: Text[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255421] Function retrieving next Letter for G/L Entries returns 'ZZZ.ZZZZZZ' if previous Letter = 'ZZZ.ZZZZZZ'.

        // [GIVEN] Previous Letter = 'ZZZ.ZZZZZZ'.
        Letter := 'ZZZ.ZZZZZZ';

        // [WHEN] Get next Letter.
        GLEntryApplication.NextLetter(Letter);

        // [THEN] New Letter = 'ZZZ.ZZZZZZ'.
        Assert.AreEqual('ZZZ.ZZZZZZ', Letter, NextLetterErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OnlyNotApplied_PostTwoUnbalancedSelectedFirst_Blanked_Blanked()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application (only not applied) is case of two selected entries (Letter = "", Amount = 1, Letter = "", Amount = 1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, '', 1, '');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], true);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aaa', 'aaa');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OnlyNotApplied_PostTwoBalancedSelectedFirst_Blanked_Blanked()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application (only not applied) is case of two selected entries (Letter = "", Amount = 1, Letter = "", Amount = -1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, '', -1, '');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], true);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'AAA', 'AAA');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyNotApplied_PostTwoUnbalancedSelectedFirst_aaa_Blanked()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application (only not applied) is case of two selected entries (Letter = "aaa", Amount = 1, Letter = "", Amount = 1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aaa', 1, '');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], true);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aaa', '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OnlyNotApplied_PostTwoUnbalancedSelectedFirst_Blanked_aaa()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application (only not applied) is case of two selected entries (Letter = "", Amount = 1, Letter = "aaa", Amount = 1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, '', 1, 'aaa');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], true);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aab', 'aaa');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyNotApplied_PostTwoUnbalancedSelectedFirst_aab_Blanked()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application (only not applied) is case of two selected entries (Letter = "aab", Amount = 1, Letter = "", Amount = 1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aab', 1, '');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], true);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aab', '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OnlyNotApplied_PostTwoUnbalancedSelectedFirst_Blanked_aab()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application (only not applied) is case of two selected entries (Letter = "", Amount = 1, Letter = "aab", Amount = 1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, '', 1, 'aab');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], true);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aac', 'aab');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyNotApplied_PostTwoUnbalancedSelectedFirst_aaa_aab()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application (only not applied) is case of two selected entries (Letter = "aaa", Amount = 1, Letter = "aab", Amount = 1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aaa', 1, 'aab');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], true);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aaa', 'aab');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OnlyNotApplied_PostTwoUnbalancedSelectedSecond_aaa_Blanked()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application (only not applied) is case of two selected entries (Letter = "aaa", Amount = 1, Letter = "", Amount = 1) and cursor at second
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aaa', 1, '');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[2], true);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aaa', 'aab');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyNotApplied_PostTwoUnbalancedSelectedSecond_Blanked_aaa()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application (only not applied) is case of two selected entries (Letter = "", Amount = 1, Letter = "aaa", Amount = 1) and cursor at second
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, '', 1, 'aaa');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[2], true);
        VerifyTwoGLEntriesLetter(GLEntryNo, '', 'aaa');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OnlyNotApplied_PostTwoUnbalancedSelectedSecond_aab_Blanked()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application (only not applied) is case of two selected entries (Letter = "aab", Amount = 1, Letter = "", Amount = 1) and cursor at second
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aab', 1, '');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[2], true);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aab', 'aac');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyNotApplied_PostTwoUnbalancedSelectedSecond_Blanked_aab()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application (only not applied) is case of two selected entries (Letter = "", Amount = 1, Letter = "aab", Amount = 1) and cursor at second
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, '', 1, 'aab');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[2], true);
        VerifyTwoGLEntriesLetter(GLEntryNo, '', 'aab');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyNotApplied_PostTwoUnbalancedSelectedSecond_aaa_aab()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857]
        // [SCENARIO 297857] Post Application (only not applied) is case of two selected entries (Letter = "aaa", Amount = 1, Letter = "aab", Amount = 1) and cursor at second
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aaa', 1, 'aab');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[2], true);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aaa', 'aab');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoUnbalancedSelectedFirst_Blanked_Blanked()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "", Amount = 1, Letter = "", Amount = 1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, '', 1, '');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aaa', 'aaa');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoUnbalancedSelectedFirst_aaa_Blanked()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "aaa", Amount = 1, Letter = "", Amount = 1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aaa', 1, '');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aaa', 'aaa');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoUnbalancedSelectedFirst_Blanked_aaa()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "", Amount = 1, Letter = "aaa", Amount = 1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, '', 1, 'aaa');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aaa', 'aaa');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoUnbalancedSelectedFirst_aab_Blanked()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "aab", Amount = 1, Letter = "", Amount = 1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aab', 1, '');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aab', 'aab');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoUnbalancedSelectedFirst_Blanked_aab()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "", Amount = 1, Letter = "aab", Amount = 1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, '', 1, 'aab');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aab', 'aab');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoUnbalancedSelectedFirst_aaa_aaa()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "aaa", Amount = 1, Letter = "aaa", Amount = 1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aaa', 1, 'aaa');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aaa', 'aaa');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoUnbalancedSelectedFirst_aab_aab()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "aab", Amount = 1, Letter = "aab", Amount = 1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aab', 1, 'aab');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aab', 'aab');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoUnbalancedSelectedFirst_aaa_aab()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "aaa", Amount = 1, Letter = "aab", Amount = 1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aaa', 1, 'aab');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aaa', 'aaa');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoUnbalancedSelectedSecond_aaa_Blanked()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "aaa", Amount = 1, Letter = "", Amount = 1) and cursor at second
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aaa', 1, '');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[2], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aaa', 'aaa');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoUnbalancedSelectedSecond_Blanked_aaa()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "", Amount = 1, Letter = "aaa", Amount = 1) and cursor at second
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, '', 1, 'aaa');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[2], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aaa', 'aaa');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoUnbalancedSelectedSecond_aab_Blanked()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "aab", Amount = 1, Letter = "", Amount = 1) and cursor at second
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aab', 1, '');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[2], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aab', 'aab');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoUnbalancedSelectedSecond_Blanked_aab()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "", Amount = 1, Letter = "aab", Amount = 1) and cursor at second
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, '', 1, 'aab');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[2], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aab', 'aab');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoUnbalancedSelectedSecond_aaa_aaa()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "aaa", Amount = 1, Letter = "aaa", Amount = 1) and cursor at second
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aaa', 1, 'aaa');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[2], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aaa', 'aaa');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoUnbalancedSelectedSecond_aab_aab()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "aab", Amount = 1, Letter = "aab", Amount = 1) and cursor at second
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aab', 1, 'aab');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[2], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aab', 'aab');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoUnbalancedSelectedSecond_aaa_aab()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "aaa", Amount = 1, Letter = "aab", Amount = 1) and cursor at second
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aaa', 1, 'aab');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[2], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'aaa', 'aaa');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoBalancedSelectedFirst_Blanked_Blanked()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "", Amount = 1, Letter = "", Amount = -1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, '', -1, '');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'AAA', 'AAA');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoBalancedSelectedFirst_aaa_Blanked()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "aaa", Amount = 1, Letter = "", Amount = -1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aaa', -1, '');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'AAA', 'AAA');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoBalancedSelectedFirst_Blanked_aaa()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "", Amount = 1, Letter = "aaa", Amount = -1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, '', -1, 'aaa');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'AAA', 'AAA');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoBalancedSelectedFirst_aab_Blanked()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "aab", Amount = 1, Letter = "", Amount = -1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aab', -1, '');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'AAB', 'AAB');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoBalancedSelectedFirst_Blanked_aab()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "", Amount = 1, Letter = "aab", Amount = -1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, '', -1, 'aab');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'AAB', 'AAB');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoBalancedSelectedFirst_aaa_aaa()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "aaa", Amount = 1, Letter = "aaa", Amount = -1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aaa', -1, 'aaa');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'AAA', 'AAA');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoBalancedSelectedFirst_aab_aab()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "aab", Amount = 1, Letter = "aab", Amount = -1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aab', -1, 'aab');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'AAB', 'AAB');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoBalancedSelectedFirst_aaa_aab()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "aaa", Amount = 1, Letter = "aab", Amount = -1) and cursor at first
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aaa', -1, 'aab');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[1], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'AAA', 'AAA');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoBalancedSelectedSecond_aaa_Blanked()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "aaa", Amount = 1, Letter = "", Amount = -1) and cursor at second
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aaa', -1, '');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[2], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'AAA', 'AAA');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoBalancedSelectedSecond_Blanked_aaa()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "", Amount = 1, Letter = "aaa", Amount = -1) and cursor at second
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, '', -1, 'aaa');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[2], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'AAA', 'AAA');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoBalancedSelectedSecond_aab_Blanked()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "aab", Amount = 1, Letter = "", Amount = -1) and cursor at second
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aab', -1, '');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[2], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'AAB', 'AAB');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoBalancedSelectedSecond_Blanked_aab()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "", Amount = 1, Letter = "aab", Amount = -1) and cursor at second
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, '', -1, 'aab');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[2], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'AAB', 'AAB');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoBalancedSelectedSecond_aaa_aaa()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "aaa", Amount = 1, Letter = "aaa", Amount = -1) and cursor at second
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aaa', -1, 'aaa');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[2], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'AAA', 'AAA');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoBalancedSelectedSecond_aab_aab()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "aab", Amount = 1, Letter = "aab", Amount = -1) and cursor at second
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aab', -1, 'aab');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[2], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'AAB', 'AAB');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTwoBalancedSelectedSecond_aaa_aab()
    var
        GLEntry: Record "G/L Entry";
        GLEntryNo: array[2] of Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297857] Post Application is case of two selected entries (Letter = "aaa", Amount = 1, Letter = "aab", Amount = -1) and cursor at second
        MockTwoGLEntries(GLEntry, GLEntryNo, 1, 'aaa', -1, 'aab');
        SetAppliesToIDAndValidate(GLEntry, GLEntryNo[2], false);
        VerifyTwoGLEntriesLetter(GLEntryNo, 'AAA', 'AAA');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UI_PostAfterSetApplies_BlankedLetter()
    var
        DummyGLEntry: Record "G/L Entry";
        ApplyGLEntries: TestPage "Apply G/L Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 297857] Set Applies-to ID and Post Application (via page) of a single entry in case of Letter = "", Amount = 1
        MockSingleGLEntry(DummyGLEntry, 1, '');

        ApplyGLEntries.Trap;
        PAGE.Run(PAGE::"Apply G/L Entries", DummyGLEntry);
        ApplyGLEntries.SetAppliesToID.Invoke;
        ApplyGLEntries."Applies-to ID".AssertEquals(UserId);
        ApplyGLEntries.PostApplication.Invoke;
        ApplyGLEntries.Letter.AssertEquals('aaa');
        ApplyGLEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_PostAfterSetApplies_NotBlankedLetter()
    var
        DummyGLEntry: Record "G/L Entry";
        ApplyGLEntries: TestPage "Apply G/L Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 297857] Set Applies-to ID and Post Application (via page) of a single entry in case of Letter = "aaa", Amount = 1
        MockSingleGLEntry(DummyGLEntry, 1, 'aaa');

        ApplyGLEntries.Trap;
        PAGE.Run(PAGE::"Apply G/L Entries", DummyGLEntry);
        ApplyGLEntries.SetAppliesToID.Invoke;
        ApplyGLEntries."Applies-to ID".AssertEquals('');
        ApplyGLEntries.PostApplication.Invoke;
        ApplyGLEntries.Letter.AssertEquals('aaa');
        ApplyGLEntries.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UI_PostAfterSetAppliesAll_BlankedLetter()
    var
        DummyGLEntry: Record "G/L Entry";
        ApplyGLEntries: TestPage "Apply G/L Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 297857] Set Applies-to ID (all) and Post Application (via page) of a single entry in case of Letter = "", Amount = 1
        MockSingleGLEntry(DummyGLEntry, 1, '');

        ApplyGLEntries.Trap;
        PAGE.Run(PAGE::"Apply G/L Entries", DummyGLEntry);
        ApplyGLEntries.SetAppliesToIDAll.Invoke;
        ApplyGLEntries."Applies-to ID".AssertEquals(UserId);
        ApplyGLEntries.PostApplication.Invoke;
        ApplyGLEntries.Letter.AssertEquals('aaa');
        ApplyGLEntries.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UI_PostAfterSetAppliesAll_NotBlankedLetter()
    var
        DummyGLEntry: Record "G/L Entry";
        ApplyGLEntries: TestPage "Apply G/L Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 297857] Set Applies-to ID (all) and Post Application (via page) of a single entry in case of Letter = "aaa", Amount = 1
        MockSingleGLEntry(DummyGLEntry, 1, 'aaa');

        ApplyGLEntries.Trap;
        PAGE.Run(PAGE::"Apply G/L Entries", DummyGLEntry);
        ApplyGLEntries.SetAppliesToIDAll.Invoke;
        ApplyGLEntries."Applies-to ID".AssertEquals(UserId);
        ApplyGLEntries.PostApplication.Invoke;
        ApplyGLEntries.Letter.AssertEquals('aaa');
        ApplyGLEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_SetAppliesAfterSetAppliesAll_BlankedLetter()
    var
        DummyGLEntry: Record "G/L Entry";
        ApplyGLEntries: TestPage "Apply G/L Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 297857] "Set Applies-to ID" after "Applies-to ID (all)" (via page) of a single entry in case of Letter = ""
        MockSingleGLEntry(DummyGLEntry, 1, '');

        ApplyGLEntries.Trap;
        PAGE.Run(PAGE::"Apply G/L Entries", DummyGLEntry);
        ApplyGLEntries.SetAppliesToIDAll.Invoke;
        ApplyGLEntries."Applies-to ID".AssertEquals(UserId);
        ApplyGLEntries.SetAppliesToID.Invoke;
        ApplyGLEntries."Applies-to ID".AssertEquals('');
        ApplyGLEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_SetAppliesAfterSetAppliesAll_NotBlankedLetter()
    var
        DummyGLEntry: Record "G/L Entry";
        ApplyGLEntries: TestPage "Apply G/L Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 297857] "Set Applies-to ID" after "Applies-to ID (all)" (via page) of a single entry in case of Letter = "aaa"
        MockSingleGLEntry(DummyGLEntry, 1, 'aaa');

        ApplyGLEntries.Trap;
        PAGE.Run(PAGE::"Apply G/L Entries", DummyGLEntry);
        ApplyGLEntries.SetAppliesToIDAll.Invoke;
        ApplyGLEntries."Applies-to ID".AssertEquals(UserId);
        ApplyGLEntries.SetAppliesToID.Invoke;
        ApplyGLEntries."Applies-to ID".AssertEquals('');
        ApplyGLEntries.Close();
    end;

    local procedure ApplyGLEntries(No: Code[20])
    var
        ChartOfAccounts: TestPage "Chart of Accounts";
    begin
        ChartOfAccounts.OpenEdit;
        ChartOfAccounts.FILTER.SetFilter("No.", No);
        ChartOfAccounts."Apply Entries".Invoke;  // Invokes ApplyGeneralLedgerEntriesPageHandler.
    end;

    local procedure CreateAndPostGeneralJournalLines(var GenJournalLine: Record "Gen. Journal Line")
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibrarySales.CreateCustomer(Customer);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandInt(500));  // Taken Random Amount.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, Customer."No.", -GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure MockGLEnty(GLAccountNo: Code[20]; NewAmount: Decimal; NewLetter: Text[10]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        with GLEntry do begin
            Init();
            "Entry No." := LibraryUtility.GetNewRecNo(GLEntry, FieldNo("Entry No."));
            "G/L Account No." := GLAccountNo;
            Amount := NewAmount;
            Letter := NewLetter;
            Insert();
            exit("Entry No.");
        end;
    end;

    local procedure MockSingleGLEntry(var GLEntry: Record "G/L Entry"; Amount: Decimal; Letter: Text[10])
    begin
        GLEntry."G/L Account No." := LibraryUtility.GenerateGUID();
        MockGLEnty(GLEntry."G/L Account No.", Amount, Letter);
        GLEntry.SetRange("G/L Account No.", GLEntry."G/L Account No.");
    end;

    local procedure MockTwoGLEntries(var GLEntry: Record "G/L Entry"; var GLEntryNo: array[2] of Integer; Amount1: Decimal; Letter1: Text[10]; Amount2: Decimal; Letter2: Text[10])
    begin
        GLEntry."G/L Account No." := LibraryUtility.GenerateGUID();
        GLEntryNo[1] := MockGLEnty(GLEntry."G/L Account No.", Amount1, Letter1);
        GLEntryNo[2] := MockGLEnty(GLEntry."G/L Account No.", Amount2, Letter2);
        GLEntry.SetRange("G/L Account No.", GLEntry."G/L Account No.");
    end;

    local procedure OpenGLRegistersPage(var GLRegisters: TestPage "G/L Registers")
    begin
        GLRegisters.OpenEdit;
        GLRegisters.First;
    end;

    local procedure SetAppliesToIDAndValidate(var GLEntry: Record "G/L Entry"; SelectedGLEntryNo: Integer; OnlyNotApplied: Boolean)
    var
        GLEntry2: Record "G/L Entry";
        GLEntryApplication: Codeunit "G/L Entry Application";
    begin
        GLEntry2.Copy(GLEntry);
        GLEntryApplication.SetAppliesToID(GLEntry2, OnlyNotApplied);
        GLEntry.Get(SelectedGLEntryNo);
        GLEntryApplication.Validate(GLEntry);
    end;

    local procedure VerifyReversedEntries(GenJournalLine: Record "Gen. Journal Line")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GenJournalLine."Bal. Account No.");
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.FindFirst();
        GLEntry.TestField(Reversed, true);
        GLEntry.TestField(Letter, '');
    end;

    local procedure VerifyTwoGLEntriesLetter(GLEntryNo: array[2] of Integer; ExpectedLetter1: Text[10]; ExpectedLetter2: Text[10])
    begin
        VerifyGLEntryLetter(GLEntryNo[1], ExpectedLetter1);
        VerifyGLEntryLetter(GLEntryNo[2], ExpectedLetter2);
    end;

    local procedure VerifyGLEntryLetter(GLEntryNo: Integer; ExpectedLetter: Text[10])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Get(GLEntryNo);
        GLEntry.TestField(Letter, ExpectedLetter);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ApplyGLEntriesPageHandler(var ApplyGLEntries: TestPage "Apply G/L Entries")
    begin
        ApplyGLEntries.First;
        ApplyGLEntries.SetAppliesToID.Invoke;
        ApplyGLEntries.Last;
        ApplyGLEntries.SetAppliesToID.Invoke;
        ApplyGLEntries.PostApplication.Invoke;
        ApplyGLEntries.Close();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReverseEntriesModalPageHandler(var ReverseTransactionEntries: TestPage "Reverse Transaction Entries")
    begin
        ReverseTransactionEntries.Reverse.Invoke;
    end;
}
#endif
