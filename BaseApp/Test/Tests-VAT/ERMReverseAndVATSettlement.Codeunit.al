codeunit 134130 "ERM Reverse And VAT Settlement"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Settlement]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        ReversalError: Label 'You cannot reverse %1 No. %2 because the entry is closed.', Comment = '%1: Table Caption;%2: Field Value';
        VATBaseError: Label '%1 amount must be %2 in %3.';
        ReverseDateCompressErr: Label 'The transaction cannot be reversed, because the %1 has been compressed.', Comment = '%1 - Table Name';
        DocNo: Label 'Test1';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcVATSettlementAndVATEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATAmount: Decimal;
    begin
        // [SCENARIO] Check VAT Settlement VAT Entry after Run VAT Settlement Batch job for Posted General Journal Lines.

        // Setup: First run VAT Settlement Report to Calculate VAT Entry for all records, then Create and Post General Journal Line and
        // Run VAT Settlement Report for Posted Entry only.
        Initialize;
        CalcAndVATSettlement(LibraryERM.CreateGLAccountNo, DocNo);
        CreatePostGeneralJournalLine(GenJournalLine, WorkDate);
        VATAmount :=
          FindVATAmount(GenJournalLine."VAT Bus. Posting Group", GenJournalLine."VAT Prod. Posting Group", GenJournalLine.Amount);

        // Exercise: Run VAT Settlement Batch Job.
        CalcAndVATSettlement(GenJournalLine."Bal. Account No.", GenJournalLine."Document No.");

        // Verify: Verify VAt Settlement VAt Entry has been created.
        VerifyVATEntry(GenJournalLine."Document No.", -VATAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcVATSettlementAndReverse()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Reverse]
        // [SCENARIO] Check Reverse Transaction Error after Run VAT Settlement Batch job for Posted General Journal Lines.

        // Setup: First run VAT Settlement Report to Calculate VAT Entry for all records, then Create and Post General Journal Line and
        // VAT Settlement Report for Posted Entry only.
        Initialize;
        CalcAndVATSettlement(LibraryERM.CreateGLAccountNo, DocNo);
        CreatePostGeneralJournalLine(GenJournalLine, WorkDate);

        // Exercise: Run VAT Settlement Batch Job.
        CalcAndVATSettlement(GenJournalLine."Bal. Account No.", GenJournalLine."Document No.");

        // Verify: Verify that Error raised during Reversal on GL Account after run VAT Settlement Batch job.
        ReverseGLAccount(GenJournalLine."Account No.", GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VATEntryDateCompress()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ReversalEntry: Record "Reversal Entry";
        GLEntry: Record "G/L Entry";
        DummyVATEntry: Record "VAT Entry";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        TransactionNo: Integer;
    begin
        // [FEATURE] [Date Compress] [Reverse]
        // [SCENARIO] Check Reverse Transaction Error after Run Date Compression VAT Entry Batch job for Posted General Journal Lines.

        // [GIVEN] Posted General Journal Line with Transaction No. = 200
        Initialize;
        CreatePostGeneralJournalLine(GenJournalLine, LibraryFiscalYear.GetFirstPostingDate(true));
        TransactionNo := GetGLEntryTransactionNo(GenJournalLine."Bal. Account No.", GenJournalLine."Document No.");

        // [GIVEN] Run Date Compress Batch job for VAT Entries.
        DateCompressVATEntry(GenJournalLine."Posting Date");
        // [GIVEN] Last TransactionNo = 201 (TFS 380533)
        GLEntry.FindLast;
        GLEntry.TestField("Transaction No.", TransactionNo + 1);

        // [WHEN] Reverse posted Journal line
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(TransactionNo);

        // [THEN] Error raised 'The transaction cannot be reversed, because the VAT Entry has been compressed'
        Assert.ExpectedError(StrSubstNo(ReverseDateCompressErr, DummyVATEntry.TableCaption));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if isInitialized then
            exit;
        LibraryERMCountryData.CreateVATData;
        isInitialized := true;
        Commit();
    end;

    local procedure CreatePostGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Take Random Amount for General Journal Line.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, LibraryRandom.RandInt(100));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CalcAndVATSettlement(AccountNo: Code[20]; DocumentNo: Code[20])
    var
        CalcandPostVATSettlement: Report "Calc. and Post VAT Settlement";
    begin
        CalcandPostVATSettlement.InitializeRequest(WorkDate, WorkDate, WorkDate, DocumentNo, AccountNo, false, true);
        CalcandPostVATSettlement.SetInitialized(false);
        CalcandPostVATSettlement.SaveAsExcel(DocumentNo);
    end;

    local procedure FindVATAmount(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; Amount: Decimal): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmount: Decimal;
    begin
        VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup);
        VATAmount := Round((Amount * VATPostingSetup."VAT %") / (VATPostingSetup."VAT %" + 100));
        exit(Amount - VATAmount);
    end;

    local procedure GetGLEntryTransactionNo(GLAccountNo: Code[20]; DocumentNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::" ");
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst;
        exit(GLEntry."Transaction No.");
    end;

    local procedure DateCompressVATEntry(PostingDate: Date)
    var
        DateComprRegister: Record "Date Compr. Register";
        DateCompressVATEntries: Report "Date Compress VAT Entries";
    begin
        // Run the Date Compress VAT Entry Report with a closed Accounting Period.
        DateCompressVATEntries.InitializeRequest(
          PostingDate, PostingDate, DateComprRegister."Period Length"::Day, true, false, false, false, false);
        DateCompressVATEntries.UseRequestPage(false);
        DateCompressVATEntries.Run;
    end;

    local procedure ReverseGLAccount(GLAccountNo: Code[20]; DocumentNo: Code[20])
    var
        ReversalEntry: Record "Reversal Entry";
        VATEntry: Record "VAT Entry";
        TransactionNo: Integer;
    begin
        TransactionNo := GetGLEntryTransactionNo(GLAccountNo, DocumentNo);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst;
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(TransactionNo);
        Assert.ExpectedError(StrSubstNo(ReversalError, VATEntry.TableCaption, VATEntry."Entry No."));
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; Base: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
        Assert: Codeunit Assert;
    begin
        GeneralLedgerSetup.Get();
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange(Type, VATEntry.Type::Settlement);
        VATEntry.FindFirst;
        Assert.AreNearlyEqual(Base, VATEntry.Base, GeneralLedgerSetup."Appln. Rounding Precision",
          StrSubstNo(VATBaseError, Base, VATEntry.Base, VATEntry.TableCaption));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

