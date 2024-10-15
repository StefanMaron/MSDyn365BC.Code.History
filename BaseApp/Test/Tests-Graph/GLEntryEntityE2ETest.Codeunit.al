#if not CLEAN18
codeunit 135539 "GLEntryEntity E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [G/L Entry]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        IsInitialized: Boolean;
        ServiceNameTxt: Label 'generalLedgerEntries';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryApplicationArea.EnableFoundationSetup;
        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateVATPostingSetup;
        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdateGeneralPostingSetup;

        IsInitialized := true;
        Commit();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,GeneralJournalTemplateHandler')]
    [Scope('OnPrem')]
    procedure TestGetGLEntries()
    var
        GLEntry: Record "G/L Entry";
        GeneralJournal: TestPage "General Journal";
        LastGLEntryNo: Integer;
        TargetURL: Text;
        ResponseText: Text;
        GLEntryId: Text;
    begin
        // [SCENARIO] Create entries and use a GET method to retrieve them
        // [GIVEN] 2 entries in the G/L Entry Table with positive balance
        Initialize;

        // [WHEN] Create and Post a General Journal Line1
        LastGLEntryNo := GetLastGLEntryNumber;
        CreateAndPostGeneralJournalLineByPage(GeneralJournal);

        // [THEN] A new G/L Entry has been created
        GLEntry.Reset();
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntryNo);
        Assert.IsTrue(GLEntry.FindFirst, 'The G/L Entry should exist in the table.');
        GLEntryId := Format(GLEntry."Entry No.");

        // [WHEN] we GET all the entry from the web service
        ClearLastError;
        TargetURL := LibraryGraphMgt.CreateTargetURL(GLEntryId, PAGE::"G/L Entry Entity", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] entry should exist in the response
        if GetLastErrorText <> '' then
            Assert.ExpectedError('Request failed with error: ' + GetLastErrorText);

        Assert.IsTrue(
          LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'id', GLEntryId),
          'Could not find sales credit memo number');
    end;

    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,GeneralJournalTemplateHandler')]
    local procedure CreateAndPostGeneralJournalLineByPage(var GeneralJournal: TestPage "General Journal")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);

        // Find General Journal Template and Create General Journal Batch.
        CreateGeneralJournalBatch(GenJournalBatch);

        // Create General Journal Line.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        GeneralJournal.Trap;
        GeneralJournal.OpenEdit;
        GeneralJournal."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        GeneralJournal."Account No.".SetValue(GLAccount."No.");
        UpdateAmountOnGenJournalLine(GenJournalBatch, GeneralJournal);
        GeneralJournal."Document No.".SetValue(GenJournalBatch.Name);

        // Find G/L Account No for Bal. Account No.
        GLAccount.SetFilter("No.", '<>%1', GLAccount."No.");
        LibraryERM.CreateGLAccount(GLAccount);
        GeneralJournal."Bal. Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        GeneralJournal."Bal. Account No.".SetValue(GLAccount."No.");

        // Post General Journal Line.
        GeneralJournal.Post.Invoke;
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo);
        GenJournalBatch.Modify(true);
    end;

    local procedure UpdateAmountOnGenJournalLine(GenJournalBatch: Record "Gen. Journal Batch"; var GeneralJournal: TestPage "General Journal")
    begin
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryERM.UpdateAmountOnGenJournalLine(GenJournalBatch, GeneralJournal);
    end;

    local procedure GetLastGLEntryNumber(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.FindLast;
        exit(GLEntry."Entry No.");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(QuestionText: Text[1024]; var Relpy: Boolean)
    begin
        Relpy := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTemplateHandler(var GeneralJournalTemplateHandler: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateHandler.FILTER.SetFilter(Name, LibraryVariableStorage.DequeueText);
        GeneralJournalTemplateHandler.OK.Invoke;
    end;
}
#endif
