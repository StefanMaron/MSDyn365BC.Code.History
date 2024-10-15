codeunit 144023 "Test Apply G/L Account"
{
    // // [FEATURE] [Apply G/L Account]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        DebitAccountNo: Code[20];
        CreditAccountNo: Code[20];

    [Test]
    [HandlerFunctions('ReqPageHandlerConsolidateTrialBalance,ReqPageHandlerForImportConsolidationFromDBReport,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure RunningConsolidationReportSecondTimeCreatesNewEntries()
    var
        BusinessUnit: Record "Business Unit";
        GLEntry: Record "G/L Entry";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        EntryNo: Integer;
    begin
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=59813
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=59822
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=59812

        // Setup
        Initialize();

        // Set the consolidation accounts in the GLAccounts table
        SetCreditAndDebitConsolidationAccounts(DebitAccountNo, CreditAccountNo);

        // Add the credit and debit consolidation accounts
        AddConsolidationAccounts;

        // Create business unit
        CreateBusinessUnit(BusinessUnit);

        Commit();
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Assets);
        GenJournalTemplate.FindFirst();
        GenJournalBatch.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalBatch.FindFirst();
        // --------------------------------------------------------------------------------
        // Excercise : Run 'Import Consolidation from DB' report.
        LibraryVariableStorage.Enqueue(BusinessUnit."Starting Date");
        LibraryVariableStorage.Enqueue(BusinessUnit."Ending Date");
        LibraryVariableStorage.Enqueue(GenJournalTemplate.Name);
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);

        REPORT.Run(REPORT::"Import Consolidation from DB", true, false, BusinessUnit);

        // Verify that the 'Amount' and 'Remaining Amount' are equal
        GLEntry.SetFilter("G/L Account No.", DebitAccountNo + '|' + CreditAccountNo);

        if GLEntry.FindSet() then begin
            repeat
                Assert.AreEqual(GLEntry.Amount, GLEntry."Remaining Amount", '');
            until GLEntry.Next = 0;
        end;

        // ---------------------------------------------------------------------------------
        // Excercise : Run 'Import Consolidation frm DB' report for the second time.
        LibraryVariableStorage.Enqueue(BusinessUnit."Starting Date");
        LibraryVariableStorage.Enqueue(BusinessUnit."Ending Date");
        LibraryVariableStorage.Enqueue(GenJournalTemplate.Name);
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        Commit();

        REPORT.Run(REPORT::"Import Consolidation from DB", true, false, BusinessUnit);

        GLEntry.Reset();
        GLEntry.SetRange("G/L Account No.", DebitAccountNo);

        // Verify that the amount and remaining amount on the previously created entries
        // are set to 0 and new entries are created
        GLEntry.FindFirst();
        EntryNo := GLEntry."Entry No.";

        GLEntry.Reset();
        GLEntry.SetRange("G/L Account No.", DebitAccountNo);

        if GLEntry.FindSet() then begin
            repeat
                if GLEntry."Entry No." = EntryNo then
                    Assert.AreEqual(0, GLEntry.Amount, '');

                Assert.AreEqual(GLEntry.Amount, GLEntry."Remaining Amount", '');
            until GLEntry.Next = 0;
        end;

        // Verify that the amount and remaining amount on the previously created entries
        // are set to 0 and new entries are created
        GLEntry.Reset();
        GLEntry.SetRange("G/L Account No.", CreditAccountNo);

        GLEntry.FindFirst();
        EntryNo := GLEntry."Entry No.";

        GLEntry.Reset();
        GLEntry.SetRange("G/L Account No.", CreditAccountNo);
        if GLEntry.FindSet() then begin
            repeat
                if GLEntry."Entry No." = EntryNo then
                    Assert.AreEqual(0, GLEntry.Amount, '');

                Assert.AreEqual(GLEntry.Amount, GLEntry."Remaining Amount", '');
            until GLEntry.Next = 0;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyGLEntries()
    var
        FirstLineDocNo: Code[20];
        SecondLineDocNo: Code[20];
    begin
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=59975

        ApplyAfterPostingTransferFundsFromOneCashAccountoToAnother(FirstLineDocNo, SecondLineDocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnApplyGLEntries()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        GeneralLedgerEntriesPage: TestPage "General Ledger Entries";
        ApplyGeneralLedgerEntriesPage: TestPage "Apply General Ledger Entries";
        ChartOfAccountsPage: TestPage "Chart of Accounts";
        FirstLineDocNo: Code[20];
        SecondLineDocNo: Code[20];
    begin
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=59975

        ApplyAfterPostingTransferFundsFromOneCashAccountoToAnother(FirstLineDocNo, SecondLineDocNo);

        GLAccount.SetRange("No.", '580000');
        GLAccount.FindFirst();
        ChartOfAccountsPage.OpenView;
        ChartOfAccountsPage.GotoRecord(GLAccount);

        GeneralLedgerEntriesPage.Trap;
        ChartOfAccountsPage."Ledger E&ntries".Invoke;

        GLEntry.SetRange("Document No.", SecondLineDocNo);
        GLEntry.FindFirst();

        GeneralLedgerEntriesPage.GotoRecord(GLEntry);
        ApplyGeneralLedgerEntriesPage.Trap;
        GeneralLedgerEntriesPage."Applied E&ntries".Invoke; // Applied Entries

        ApplyGeneralLedgerEntriesPage."&Undo Application".Invoke;
        Assert.AreNotEqual(0, ApplyGeneralLedgerEntriesPage."Remaining Amount".AsDEcimal, '');
        Assert.AreEqual(true, ApplyGeneralLedgerEntriesPage.Open.AsBoolean, '');
        Assert.AreEqual(0, ApplyGeneralLedgerEntriesPage."Closed by Amount".AsDEcimal, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetAppliesToIDOnAppliedGLEntriesThrowsException()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        ChartOfAccountsPage: TestPage "Chart of Accounts";
        GeneralLedgerEntriesPage: TestPage "General Ledger Entries";
        ApplyGeneralLedgerEntriesPage: TestPage "Apply General Ledger Entries";
        FirstLineDocNo: Code[20];
        SecondLineDocNo: Code[20];
    begin
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=59975

        ApplyAfterPostingTransferFundsFromOneCashAccountoToAnother(FirstLineDocNo, SecondLineDocNo);

        GLAccount.Reset();
        GLAccount.SetRange("No.", '580000');
        GLAccount.FindFirst();
        ChartOfAccountsPage.OpenView;
        ChartOfAccountsPage.GotoRecord(GLAccount);

        GeneralLedgerEntriesPage.Trap;
        ChartOfAccountsPage."Ledger E&ntries".Invoke;

        GLEntry.SetRange("Document No.", SecondLineDocNo);
        GLEntry.FindFirst();

        GeneralLedgerEntriesPage.GotoRecord(GLEntry);
        ApplyGeneralLedgerEntriesPage.Trap;
        GeneralLedgerEntriesPage."Applied E&ntries".Invoke; // Applied Entries

        asserterror ApplyGeneralLedgerEntriesPage.SetAppliesToID.Invoke;
    end;

    [Test]
    [HandlerFunctions('DimensionSetEntriesHandler')]
    [Scope('OnPrem')]
    procedure UnbalancedApplyThrowsException()
    var
        GLAccount: Record "G/L Account";
        ChartOfAccountsPage: TestPage "Chart of Accounts";
        GeneralLedgerEntriesPage: TestPage "General Ledger Entries";
        ApplyGeneralLedgerEntriesPage: TestPage "Apply General Ledger Entries";
        NavigatePage: TestPage Navigate;
        Date1: Date;
        FirstLineDocNo: Code[20];
    begin
        // Setup - Insert 2 General Journal lines against a G/L Account and a
        // corresponding balancing accounts

        Date1 := CalcDate('<CY-1Y+27D>', WorkDate);
        FirstLineDocNo := CreatePostGenJnlLineOnDate('510000', Date1, 1000);

        // ---------------------------------------------------------------
        GLAccount.SetRange("No.", '510000');
        GLAccount.FindFirst();
        ChartOfAccountsPage.OpenView;
        ChartOfAccountsPage.GotoRecord(GLAccount);

        GeneralLedgerEntriesPage.Trap;
        ChartOfAccountsPage."Ledger E&ntries".Invoke;

        ApplyGeneralLedgerEntriesPage.Trap;
        GeneralLedgerEntriesPage.ApplyEntries.Invoke;

        ApplyGeneralLedgerEntriesPage.IncludeEntryFilter.SetValue := 'Open';

        // Select first line and verify
        ApplyGeneralLedgerEntriesPage.FindFirstField("Document No.", FirstLineDocNo);
        Assert.AreEqual(FirstLineDocNo, ApplyGeneralLedgerEntriesPage."Document No.".Value, 'GL entry not found.');
        Assert.AreEqual('', ApplyGeneralLedgerEntriesPage."Applies-to ID".Value, 'Applies-to ID field is not empty.');

        // Invoke 'Set Applies-to ID' action on the first line
        ApplyGeneralLedgerEntriesPage.SetAppliesToID.Invoke;

        // Verify data on first line
        ApplyGeneralLedgerEntriesPage.FindFirstField("Document No.", FirstLineDocNo);

        NavigatePage.Trap;
        ApplyGeneralLedgerEntriesPage."&Navigate".Invoke;
        Assert.AreEqual(2, NavigatePage."No. of Records".AsInteger, '');
        NavigatePage.Close;

        ApplyGeneralLedgerEntriesPage.Dimensions.Invoke;

        // Invoke Post
        asserterror ApplyGeneralLedgerEntriesPage."Post Application".Invoke;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResetAppliesToIDOnAppliesGLEntiesPage()
    var
        GeneralLedgerEntries: TestPage "General Ledger Entries";
        ApplyGeneralLedgerEntries: TestPage "Apply General Ledger Entries";
        GLAccountNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 381565] Amount, Applied Amount and Balance controls should be zero after reset Applies-to ID on Apply General Ledger Entries page
        Initialize();

        // [GIVEN] G/L Entry "GLE" with Amount = 100
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        Amount := MockGLEntry(GLAccountNo);
        GeneralLedgerEntries.OpenView;
        GeneralLedgerEntries.FILTER.SetFilter("G/L Account No.", GLAccountNo);
        ApplyGeneralLedgerEntries.Trap;
        GeneralLedgerEntries.ApplyEntries.Invoke;

        // [GIVEN] G/L Entry "GLE" has Applied-to ID set on Apply General Ledger Entries page
        // [GIVEN] Amount field is 100, Applied Amount is 0, Balance is 100
        ApplyGeneralLedgerEntries.SetAppliesToID.Invoke;
        VerifyAppliedAmountAndBalanceOnApplnGLEntriesPage(ApplyGeneralLedgerEntries, Amount, 0, Amount, UserId);

        // [WHEN] Invoke Set Applies-to ID for G/L Entry "GLE"
        ApplyGeneralLedgerEntries.SetAppliesToID.Invoke;

        // [THEN] Amount = 0, Applied Amount = 0, Balance = 0 on Apply General Ledger Entries page
        VerifyAppliedAmountAndBalanceOnApplnGLEntriesPage(ApplyGeneralLedgerEntries, 0, 0, 0, '');
    end;

    local procedure Initialize()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if not IsInitialized then begin
            DebitAccountNo := Format(LibraryRandom.RandIntInRange(80000, 90000));
            CreditAccountNo := Format(LibraryRandom.RandIntInRange(80000, 90000));
            GenJournalLine.DeleteAll();
            IsInitialized := true;
        end;
    end;

    [HandlerFunctions('GJTemplateListHandler,ConfirmationHandler,GeneralMessageHandler')]
    local procedure ApplyAfterPostingTransferFundsFromOneCashAccountoToAnother(var FirstLineDocNo: Code[20]; var SecondLineDocNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        ChartOfAccountsPage: TestPage "Chart of Accounts";
        GeneralLedgerEntriesPage: TestPage "General Ledger Entries";
        ApplyGeneralLedgerEntriesPage: TestPage "Apply General Ledger Entries";
        Date1: Date;
        Date2: Date;
    begin
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=59975

        // Setup - Insert 2 General Journal lines against a G/L Account and a
        // corresponding balancing accounts

        Date1 := CalcDate('<CY-1Y+27D>', WorkDate);
        Date2 := CalcDate('<CY-1Y+31D>', WorkDate);
        FirstLineDocNo := CreatePostGenJnlLineOnDate('580000', Date1, 1000);
        SecondLineDocNo := CreatePostGenJnlLineOnDate('580000', Date2, -1000);

        // ---------------------------------------------------------------
        GLAccount.SetRange("No.", '580000');
        GLAccount.FindFirst();
        ChartOfAccountsPage.OpenView;
        ChartOfAccountsPage.GotoRecord(GLAccount);

        GeneralLedgerEntriesPage.Trap;
        ChartOfAccountsPage."Ledger E&ntries".Invoke;

        ApplyGeneralLedgerEntriesPage.Trap;
        GeneralLedgerEntriesPage.ApplyEntries.Invoke;

        ApplyGeneralLedgerEntriesPage.IncludeEntryFilter.SetValue := 'Open';

        // Select first line and verify
        ApplyGeneralLedgerEntriesPage.FindFirstField("Document No.", FirstLineDocNo);
        Assert.AreEqual(FirstLineDocNo, ApplyGeneralLedgerEntriesPage."Document No.".Value, 'GL entry not found.');
        Assert.AreEqual('', ApplyGeneralLedgerEntriesPage."Applies-to ID".Value, 'Applies-to ID field is not empty.');

        // Invoke 'Set Applies-to ID' action on the first line
        ApplyGeneralLedgerEntriesPage.SetAppliesToID.Invoke;

        // Select second line and verify
        ApplyGeneralLedgerEntriesPage.FindFirstField("Document No.", SecondLineDocNo);
        Assert.AreEqual(SecondLineDocNo, ApplyGeneralLedgerEntriesPage."Document No.".Value, 'GL entry not found.');
        Assert.AreEqual('', ApplyGeneralLedgerEntriesPage."Applies-to ID".Value, 'Applies-to ID fieldis not empty.');

        // Invoke 'Set Applies-to ID' action on the second line
        ApplyGeneralLedgerEntriesPage.SetAppliesToID.Invoke;

        // Verify data on first line
        ApplyGeneralLedgerEntriesPage.FindFirstField("Document No.", FirstLineDocNo);
        VerifyAppliedAmountAndBalanceOnApplnGLEntriesPage(ApplyGeneralLedgerEntriesPage, 1000, -1000, 0, UserId);

        // Verify data on the second line
        ApplyGeneralLedgerEntriesPage.FindFirstField("Document No.", SecondLineDocNo);
        VerifyAppliedAmountAndBalanceOnApplnGLEntriesPage(ApplyGeneralLedgerEntriesPage, -1000, 1000, 0, UserId);

        // Invoke Post
        ApplyGeneralLedgerEntriesPage."Post Application".Invoke;

        // ------------------------------------------------------------------------------
        ApplyGeneralLedgerEntriesPage.First;
        VerifyAppliedAmountAndBalanceOnApplnGLEntriesPage(ApplyGeneralLedgerEntriesPage, 0, 0, 0, '');
    end;

    local procedure AddConsolidationAccounts()
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount."No." := DebitAccountNo;
        GLAccount.Name := 'Cons1';
        GLAccount.Insert(true);

        GLAccount.Init();
        GLAccount."No." := CreditAccountNo;
        GLAccount.Name := 'Cons2';
        GLAccount.Insert(true);
    end;

    local procedure SetCreditAndDebitConsolidationAccounts(DebitConsolidationAccount: Code[20]; CreditConsolidationAccount: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.ModifyAll("Consol. Debit Acc.", DebitConsolidationAccount, true);
        GLAccount.ModifyAll("Consol. Credit Acc.", CreditConsolidationAccount, true);
    end;

    local procedure CreateBusinessUnit(var BusinessUnit: Record "Business Unit")
    var
        CompanyInfo: Record "Company Information";
    begin
        LibraryERM.CreateBusinessUnit(BusinessUnit);
        BusinessUnit.Name := 'Cons1';
        CompanyInfo.FindFirst();
        BusinessUnit."Company Name" := CopyStr(CompanyInfo.Name, 1, MaxStrLen(BusinessUnit."Company Name"));
        BusinessUnit."Starting Date" := CalcDate('<CY-1Y+1D>', WorkDate);
        BusinessUnit."Ending Date" := CalcDate('<CY>', WorkDate);
        BusinessUnit.Modify(true);
    end;

    local procedure CreatePostGenJnlLineOnDate(GLAccountNo: Code[20]; PostingDate: Date; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure MockGLEntry(GLAccountNo: Code[20]): Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        with GLEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(GLEntry, FieldNo("Entry No."));
            "G/L Account No." := GLAccountNo;
            "Posting Date" := WorkDate;
            Amount := LibraryRandom.RandDecInRange(10, 20, 2);
            Open := true;
            "Remaining Amount" := Amount;
            Insert;
            exit(Amount);
        end;
    end;

    local procedure VerifyAppliedAmountAndBalanceOnApplnGLEntriesPage(var ApplyGeneralLedgerEntries: TestPage "Apply General Ledger Entries"; Amount: Decimal; AppliedAmount: Decimal; Balance: Decimal; AppliesToID: Code[50])
    begin
        ApplyGeneralLedgerEntries.ShowAmount.AssertEquals(Amount); // Amount
        ApplyGeneralLedgerEntries.ShowAppliedAmount.AssertEquals(AppliedAmount); // Applied Amount
        ApplyGeneralLedgerEntries.ShowTotalAppliedAmount.AssertEquals(Balance); // Balance
        ApplyGeneralLedgerEntries."Applies-to ID".AssertEquals(AppliesToID);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReqPageHandlerForImportConsolidationFromDBReport(var ReqPage: TestRequestPage "Import Consolidation from DB")
    var
        DequeueVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVar);
        ReqPage.StartingDate.SetValue := DequeueVar;         // Starting Date

        LibraryVariableStorage.Dequeue(DequeueVar);
        ReqPage.EndingDate.SetValue := DequeueVar;           // Ending Date

        LibraryVariableStorage.Dequeue(DequeueVar);
        ReqPage.JournalTemplateName.SetValue := DequeueVar;       // Journal Template Name

        LibraryVariableStorage.Dequeue(DequeueVar);
        ReqPage.JournalBatchName.SetValue := DequeueVar;       // Journal Batch Name

        ReqPage.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReqPageHandlerConsolidateTrialBalance(var ConsolidatedTrialBalance: TestRequestPage "Consolidated Trial Balance")
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmationHandler(Question: Text[1024]; var Answer: Boolean)
    begin
        Answer := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure GeneralMessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GJTemplateListHandler(var GJTemplateListPage: TestPage "General Journal Template List")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.FindFirst();

        GJTemplateListPage.GotoRecord(GenJournalTemplate);
        GJTemplateListPage.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSetEntriesHandler(var DimensionSetEntriesPage: TestPage "Dimension Set Entries")
    begin
        DimensionSetEntriesPage.OK.Invoke;
    end;
}

