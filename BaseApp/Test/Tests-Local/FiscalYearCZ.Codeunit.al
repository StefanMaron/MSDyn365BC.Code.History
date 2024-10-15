codeunit 144002 "Fiscal Year CZ"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        IsInitialized: Boolean;
        ConfirmCloseAccPeriodQst: Label 'This function closes the fiscal year from %1 to %2. Once the fiscal year is closed it cannot be opened again, and the periods in the fiscal year cannot be changed.\\Do you want to close the fiscal year?';
        ConfirmDeleteGLAccountQst: Label 'Please be aware that accounting requirements may exist that dictates you to save a certain number of years of accounting data. Are you sure you want to delete the G/L Account?';
        UnexpectedConfirmErr: Label 'Unexpected confirm handler: %1';

    [Test]
    [HandlerFunctions('ExtenedConfirmHandler')]
    [Scope('OnPrem')]
    procedure CannotDeleteConfirmedGLAccountInClosedAccountPeriodWhenIsNotAllowedInCZSetup()
    var
        GLAccount: Record "G/L Account";
    begin
        // [SCENARIO 258044] Stan cannot delete G/L Account having posted G/L entries in closed accounting period with posting date later GLSetup."Allow G/L Acc. Deletion Before"
        // [SCENARIO 258044] when GLSetup."Delete Card with Entries" = FALSE.
        Initialize;

        LibraryERM.CreateGLAccount(GLAccount);
        LibraryFiscalYear.UpdateAllowGAccDeletionBeforeDateOnGLSetup(LibraryFiscalYear.GetPastNewYearDate(5));
        LibraryFiscalYear.UpdateDeleteCardWithEntriesOnGLSetup(false);
        IntitializeGLAccountWithClosedEntriesClosedAccountingPeriod(GLAccount);

        LibraryVariableStorage.Enqueue(true);
        asserterror GLAccount.Delete(true);

        Assert.ExpectedError('Delete Card with Entries must have a value in General Ledger Setup');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        // Lazy Setup.
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;

        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData;
        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
    end;

    local procedure IntitializeGLAccountWithClosedEntriesClosedAccountingPeriod(GLAccount: Record "G/L Account")
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        LibraryFiscalYear.CloseFiscalYear;
        LibraryFiscalYear.CreateFiscalYear;
        Amount := LibraryRandom.RandIntInRange(10, 20);

        CreateAndPostGenJnlLine(GenJournalLine, GLAccount."No.", Amount);
        CreateAndPostGenJnlLine(GenJournalLine, GLAccount."No.", -Amount);

        Commit();
        LibraryFiscalYear.CloseFiscalYear;
    end;

    local procedure CreateAndPostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount);
        GenJournalLine.Validate("Posting Date", LibraryFiscalYear.GetFirstPostingDate(false));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ExtenedConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        case Question of
            ConfirmCloseAccPeriodQst:
                Reply := true;
            ConfirmDeleteGLAccountQst:
                Reply := LibraryVariableStorage.DequeueBoolean;
            else
                Error(StrSubstNo(UnexpectedConfirmErr, Question));
        end;
    end;
}

