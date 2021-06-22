codeunit 134092 "ERM Consolidation"
{
    Permissions = TableData "G/L Entry" = imd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Consolidation]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        IsInitialized: Boolean;
        GLEntryErrTagTok: Label 'ErrorText_Number__Control23';
        GLEntryDimensionErr: Label 'G/L Entry %1: Select Dimension Value Code %2 for the Dimension Code %3 for G/L Account %4.', Comment = '%1 = G/L Entry No., %2 = Expected Dimension Value, %3 = Dimension Code, %4 = G/L Account No.';

    [Test]
    [Scope('OnPrem')]
    procedure ConsolidateLocalDebitCreditGLAccounts()
    var
        DebitGLAcc: Record "G/L Account";
        CreditGLAcc: Record "G/L Account";
        BusinessUnit: Record "Business Unit";
        TempGLEntry: Record "G/L Entry" temporary;
        DocNo: Code[20];
        Amount: Decimal;
        ExpectedDebitAmount: Decimal;
        ExpectedCreditAmount: Decimal;
    begin
        // [SCENARIO 372046] G/L Account with Debit/Credit Balance should be consolidated to Debit/Credit Consolidation Account

        Initialize;
        Amount := LibraryRandom.RandDec(100, 2);
        // [GIVEN] G/L Account "X1" with Debit Balance = 100, "Cons. Debit Acc" = "A1", "Cons. Credit Acc." = "B1"
        ExpectedDebitAmount :=
          PostDebitCreditGenJnlLines(DebitGLAcc, TempGLEntry, Amount * LibraryRandom.RandIntInRange(3, 5), -Amount);
        // [GIVEN] G/L Account "X2" with Credit Balance = -100 "Cons. Debit Acc" = "A2", "Cons. Credit Acc." = "B2"
        ExpectedCreditAmount :=
          PostDebitCreditGenJnlLines(CreditGLAcc, TempGLEntry, Amount, -Amount * LibraryRandom.RandIntInRange(3, 5));

        // [WHEN] Run Consolidation with "Data Source" = "Local Currency"
        DocNo :=
          RunConsolidation(TempGLEntry, DebitGLAcc, CreditGLAcc, BusinessUnit."Data Source"::"Local Curr. (LCY)");
        // [THEN] Consolidation G/L Entry created with "G/L Account No." = "A1" and "Amount" = 100
        VerifyGLEntryAmount(DocNo, DebitGLAcc."Consol. Debit Acc.", ExpectedDebitAmount);
        // [THEN] Consolidation G/L Entry created with "G/L Account No." = "B2" and "Amount" = -100
        VerifyGLEntryAmount(DocNo, CreditGLAcc."Consol. Credit Acc.", ExpectedCreditAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsolidateACYDebitCreditGLAccounts()
    var
        DebitGLAcc: Record "G/L Account";
        CreditGLAcc: Record "G/L Account";
        BusinessUnit: Record "Business Unit";
        TempGLEntry: Record "G/L Entry" temporary;
        DocNo: Code[20];
        Amount: Decimal;
        ExpectedDebitAmount: Decimal;
        ExpectedCreditAmount: Decimal;
    begin
        // [FEATURE] [ACY]
        // [SCENARIO 372046] G/L Account with Debit/Credit Add. Currency Balance should be consolidated to Debit/Credit Consolidation Account

        Initialize;
        UpdateAddnlReportingCurrency(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, 1, LibraryRandom.RandDec(100, 2)));
        Amount := LibraryRandom.RandDec(100, 2);
        // [GIVEN] G/L Account "X1" with Debit Balance = 100, "Cons. Debit Acc" = "A1", "Cons. Credit Acc." = "B1"
        ExpectedDebitAmount :=
          PostDebitCreditGenJnlLines(DebitGLAcc, TempGLEntry, Amount * LibraryRandom.RandIntInRange(3, 5), -Amount);
        // [GIVEN] G/L Account "X2" with Credit Balance = -100 "Cons. Debit Acc" = "A2", "Cons. Credit Acc." = "B2"
        ExpectedCreditAmount :=
          PostDebitCreditGenJnlLines(CreditGLAcc, TempGLEntry, Amount, -Amount * LibraryRandom.RandIntInRange(3, 5));

        // [WHEN] Run Consolidation with "Data Source" = "Additional Currency"
        DocNo := RunConsolidation(TempGLEntry, DebitGLAcc, CreditGLAcc, BusinessUnit."Data Source"::"Add. Rep. Curr. (ACY)");
        // [THEN] Consolidation G/L Entry created with "G/L Account No." = "A1" and "Additional Currency Amount" = 100
        VerifyGLEntryAmountACY(DocNo, DebitGLAcc."Consol. Debit Acc.", ExpectedDebitAmount);
        // [THEN] Consolidation G/L Entry created with "G/L Account No." = "B2" and "Additional Currency Amount" = -100
        VerifyGLEntryAmountACY(DocNo, CreditGLAcc."Consol. Credit Acc.", ExpectedCreditAmount);
    end;

    [Test]
    [HandlerFunctions('ConsolidationTestDatabaseReportHandler')]
    [Scope('OnPrem')]
    procedure PrintGLAccountInConsolidationTestDatabaseReport()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 372262] "G/L Account No." should be printed in "Consolidation - Test Database" report if related G/L Entry exists

        Initialize;
        // [GIVEN] G/L Account = "X" with Consolidation Setup and posted G/L Entry
        CreateGLAccountWithConsolidationSetup(GLAccount);
        InsertGLEntry(GLAccount."No.");

        // [WHEN] Run "Consolidation - Test Database" report
        LibraryVariableStorage.Enqueue('');
        RunConsolidationTestDatabase;

        // [THEN] G/L Account = "X" is printed
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('G_L_Account__No__', GLAccount."No."));
    end;

    [Test]
    [HandlerFunctions('GLConsolidationEliminationsRPH')]
    [Scope('OnPrem')]
    procedure GLConsolidationEliminationsBooleanColumnType()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [Reports] [UT]
        // [SCENARIO 375924] "G/L Consolidation Eliminations" report dataset uses "0"/"1" for boolean columns
        Initialize;

        LibraryERM.SelectGenJnlBatch(GenJournalBatch);

        // [WHEN] Run "G/L Consolidation Eliminations" report
        Commit();
        RunGLConsolidationEliminationsRep(GenJournalBatch);

        // [THEN] Report dataset contains "0"/"1" for boolean columns "FirstLine" and "FirstLine2"
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('FirstLine2', '1');
    end;

    [Test]
    [HandlerFunctions('ConsolidationTestDatabaseReportHandler')]
    [Scope('OnPrem')]
    procedure PrintErrorAccountDimInConsolidationTestDatabaseReport()
    var
        GLAccount: Record "G/L Account";
        BusinessUnit: Record "Business Unit";
        DefaultDimension: Record "Default Dimension";
        DimSetID: Integer;
        GLEntryNo: Integer;
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 380422] "Consolidation - Test Database" report log error if wrong G/L Entry dimension value set.
        Initialize;

        // [GIVEN] G/L Account = "X" with Consolidation Setup
        CreateGLAccountWithConsolidationSetup(GLAccount);

        // [GIVEN] Business Unit "BU" with current company
        CreateBusinessUnit(BusinessUnit, BusinessUnit."Data Source"::"Local Curr. (LCY)");

        // [GIVEN] Default Dimension with Dimension Code = "D1", Dimension value = "V1"
        // [GIVEN] "D1"."Value Posting" = "Value Posting"::"Same Code"
        // [GIVEN] Dimension Set entry "DS": "DS".Dimension Code = "D1", "DS".Dimension Value = "V2"
        // [GIVEN] Selected Dimension code for checking in report is "D1"
        CreateSelectedDim(DefaultDimension, DimSetID, GLAccount."No.");

        // [GIVEN] G/L Entry "GLE": "GLE"."G/L Account" = "X", "GLE".BusinessUnit = "BU", "GLE".Dimension Set = "DS"
        GLEntryNo := InsertGLEntryWithBusinessUnit(GLAccount."No.", BusinessUnit.Code, DimSetID);

        // [WHEN] Run "Consolidation - Test Database" report filtered on Business Unit "BU"
        LibraryVariableStorage.Enqueue(DefaultDimension."Dimension Code");
        Commit();
        REPORT.Run(REPORT::"Consolidation - Test Database", true, false, BusinessUnit);

        // [THEN] Error "G/L Entry "GLE": Select Dimension Value Code "V1" for the Dimension Code "D1 for G/L Account "X" has been logged.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementTagWithValueExists(
          GLEntryErrTagTok,
          StrSubstNo(
            GLEntryDimensionErr, GLEntryNo, DefaultDimension."Dimension Value Code", DefaultDimension."Dimension Code", GLAccount."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsolidateLocalDebitCreditGLAccountsTemporaryGLEntries()
    var
        DebitGLAcc: Record "G/L Account";
        CreditGLAcc: Record "G/L Account";
        BusinessUnit: Record "Business Unit";
        TempGLEntry: Record "G/L Entry" temporary;
        DocNo: Code[20];
        Amount: Decimal;
        ExpectedDebitAmount: Decimal;
        ExpectedCreditAmount: Decimal;
    begin
        // [SCENARIO 273629] Consolidation Debit/Credit account is chosen based on amounts in generated temporary G/L Entries

        Initialize;
        Amount := LibraryRandom.RandDec(100, 2);

        // [GIVEN] G/L Account "X1" with "Cons. Debit Acc" = "A1", "Cons. Credit Acc." = "B1"
        // [GIVEN] Temporary G/L Entry with "G/L Account No." = "X1", "Debit Amount" = 200
        // [GIVEN] Temporary G/L Entry with "G/L Account No." = "X1", "Credit Amount" = 100
        ExpectedDebitAmount :=
          PrepareTempDebitCreditGLEntries(DebitGLAcc, TempGLEntry, Amount * LibraryRandom.RandIntInRange(3, 5), Amount);

        // [GIVEN] G/L Account "X2" with "Cons. Debit Acc" = "A2", "Cons. Credit Acc." = "B2"
        // [GIVEN] Temporary G/L Entry with "G/L Account No." = "X2", "Debit Amount" = 100
        // [GIVEN] Temporary G/L Entry with "G/L Account No." = "X2", "Credit Amount" = 200
        ExpectedCreditAmount :=
          PrepareTempDebitCreditGLEntries(CreditGLAcc, TempGLEntry, Amount, Amount * LibraryRandom.RandIntInRange(3, 5));

        // [WHEN] Run Consolidation with "Data Source" = "Local Currency"
        DocNo :=
          RunConsolidation(TempGLEntry, DebitGLAcc, CreditGLAcc, BusinessUnit."Data Source"::"Local Curr. (LCY)");

        // [THEN] Consolidation G/L Entry created with "G/L Account No." = "A1" and "Amount" = 100
        VerifyGLEntryAmount(DocNo, DebitGLAcc."Consol. Debit Acc.", ExpectedDebitAmount);
        // [THEN] Consolidation G/L Entry created with "G/L Account No." = "B2" and "Amount" = -100
        VerifyGLEntryAmount(DocNo, CreditGLAcc."Consol. Credit Acc.", ExpectedCreditAmount);
    end;

    [Test]
    [HandlerFunctions('ImportConsolidationFromDBReportHandler,ConfirmHandlerYes,ConsolidatedTrialBalanceReportHandler')]
    [Scope('OnPrem')]
    procedure ImportConsolidationfromBusinessUnitWithDates()
    var
        AccountingPeriod: Record "Accounting Period";
        BusinessUnit: Record "Business Unit";
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 298236] Consolidation do not throw error, even if Business Unit's dates are not Fiscal Year dates of Business Unit's Company
        Initialize;

        // [GIVEN] No Accounting periods/Fiscal years setup
        AccountingPeriod.DeleteAll();

        // [GIVEN] Business Unit with Company set to current company
        LibraryERM.CreateBusinessUnit(BusinessUnit);
        BusinessUnit.Validate("Company Name", CompanyName);
        BusinessUnit.Validate("Starting Date", WorkDate);
        BusinessUnit.Validate("Ending Date", WorkDate + 1);
        BusinessUnit.Modify(true);
        Commit();

        // [WHEN] Report "Import Consolidation from DB" is run
        REPORT.Run(REPORT::"Import Consolidation from DB", true, false, BusinessUnit);

        // [THEN] No errors is thrown
    end;

    [Test]
    [HandlerFunctions('GLConsolidationEliminationsRPH')]
    [Scope('OnPrem')]
    procedure GLConsolidationEliminationReportIncludesBalAccountInGenJournal()
    var
        GLAccount: Record "G/L Account";
        BalGLAccount: Record "G/L Account";
        TotalingGLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 322981] G/L Consolidation Elimination report includes balanced account amount on general journal line.
        Initialize;

        // [GIVEN] G/L Accounts "A", "B".
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(BalGLAccount);

        // [GIVEN] Totaling g/l account "T" with totaling formula "A"|"B".
        LibraryERM.CreateGLAccount(TotalingGLAccount);
        TotalingGLAccount.Totaling := StrSubstNo('%1|%2', GLAccount."No.", BalGLAccount."No.");
        TotalingGLAccount.Modify(true);

        // [GIVEN] Gen. journal line with account no. = "A" and bal. account no. = "B". Amount = "X".
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, 0,
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", BalGLAccount."No.", LibraryRandom.RandDec(100, 2));

        // [WHEN] Run "G/L Consolidation Eliminations" report.
        Commit();
        RunGLConsolidationEliminationsRep(GenJournalBatch);

        // [THEN] The amount for g/l account "A" in the report layout = "X".
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('GLAcc2No', GLAccount."No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('Amount_GenJournalLine', GenJournalLine.Amount);

        // [THEN] The amount for balanced g/l account "B" in the report layout = -"X".
        // [THEN] The description of this entry is equal to the name of "B".
        LibraryReportDataset.SetRange('GLAcc2No', BalGLAccount."No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('Amount_GenJournalLine', -GenJournalLine.Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('Desc_GenJournalLine', BalGLAccount.Name);

        // [THEN] The amount for totaling g/l account "T" = 0.
        LibraryReportDataset.SetRange('No2__GLAccount', TotalingGLAccount."No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('EliminationAmount', 0);

        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore;
        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        IsInitialized := true;
    end;

    local procedure CreateGLAccountWithConsolidationSetup(var GLAccount: Record "G/L Account")
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Consol. Debit Acc.", LibraryERM.CreateGLAccountNo);
        GLAccount.Validate("Consol. Credit Acc.", LibraryERM.CreateGLAccountNo);
        GLAccount.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateBusinessUnit(var BusinessUnit: Record "Business Unit"; DataSource: Option)
    begin
        LibraryERM.CreateBusinessUnit(BusinessUnit);
        BusinessUnit.Validate("Company Name", CompanyName);
        BusinessUnit.Validate("Residual Account", LibraryERM.CreateGLAccountNo);
        BusinessUnit.Validate("Data Source", DataSource);
        BusinessUnit.Modify(true);
    end;

    local procedure CreateSelectedDim(var DefaultDimension: Record "Default Dimension"; var DimSetID: Integer; GLAccountCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        SelectedDimension: Record "Selected Dimension";
        DimensionSelectionBuffer: Record "Dimension Selection Buffer";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension,
          DATABASE::"G/L Account", GLAccountCode, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Same Code");
        DefaultDimension.Modify(true);
        LibraryDimension.CreateDimensionValue(DimensionValue, DefaultDimension."Dimension Code");
        Commit();
        DimSetID := LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code);
        SelectedDimension.Init();
        LibraryDimension.CreateSelectedDimension(SelectedDimension, 3,
          REPORT::"Consolidation - Test Database", '', DefaultDimension."Dimension Code");
        DimensionSelectionBuffer.Init();
        DimensionSelectionBuffer.Code := SelectedDimension."Dimension Code";
        DimensionSelectionBuffer.Selected := true;
        DimensionSelectionBuffer.Insert();
    end;

    local procedure InsertGLEntry(GLAccNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
        GLEntry."G/L Account No." := GLAccNo;
        GLEntry."Posting Date" := WorkDate;
        GLEntry.Insert();
        exit(GLEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure InsertGLEntryWithBusinessUnit(GLAccountNo: Code[20]; BusinessUnitCode: Code[20]; DimensionSetID: Integer): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Get(InsertGLEntry(GLAccountNo));
        GLEntry."Business Unit Code" := BusinessUnitCode;
        GLEntry."Dimension Set ID" := DimensionSetID;
        GLEntry.Modify();
        exit(GLEntry."Entry No.");
    end;

    local procedure UpdateAddnlReportingCurrency(AdditionalReportingCurrency: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := AdditionalReportingCurrency;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure PostDebitCreditGenJnlLines(var GLAccount: Record "G/L Account"; var GLEntry: Record "G/L Entry"; DebitAmount: Decimal; CreditAmount: Decimal): Decimal
    begin
        CreateGLAccountWithConsolidationSetup(GLAccount);
        PostGenJnlLine(GLEntry, GLAccount."No.", DebitAmount);
        PostGenJnlLine(GLEntry, GLAccount."No.", CreditAmount);
        exit(DebitAmount + CreditAmount);
    end;

    local procedure PostGenJnlLine(var GLEntryBuffer: Record "G/L Entry"; GLAccNo: Code[20]; Amount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJnlLine, 0, GenJnlLine."Account Type"::"G/L Account", GLAccNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        FindGLEntry(GLEntry, GenJnlLine."Account No.", GenJnlLine."Document No.");
        GLEntryBuffer := GLEntry;
        GLEntryBuffer.Insert();
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; GLAccNo: Code[20]; DocNo: Code[20])
    begin
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.FindFirst;
    end;

    local procedure RunConsolidation(var TempGLEntry: Record "G/L Entry" temporary; DebitGLAcc: Record "G/L Account"; CreditGLAcc: Record "G/L Account"; DateSource: Option) DocNo: Code[20]
    var
        BusinessUnit: Record "Business Unit";
        Consolidate: Codeunit Consolidate;
    begin
        DocNo := LibraryUtility.GenerateGUID;
        Consolidate.SetDocNo(DocNo);
        Consolidate.InsertGLAccount(DebitGLAcc);
        Consolidate.InsertGLAccount(CreditGLAcc);
        TempGLEntry.FindSet;
        repeat
            Consolidate.InsertGLEntry(TempGLEntry);
        until TempGLEntry.Next = 0;
        CreateBusinessUnit(BusinessUnit, DateSource);
        Consolidate.SetGlobals('', '', BusinessUnit."Company Name", '', '', '', 0, WorkDate, WorkDate);
        Consolidate.Run(BusinessUnit);
    end;

    local procedure RunGLConsolidationEliminationsRep(GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        REPORT.Run(REPORT::"G/L Consolidation Eliminations", true, false);
    end;

    local procedure RunConsolidationTestDatabase()
    var
        BusinessUnit: Record "Business Unit";
    begin
        CreateBusinessUnit(BusinessUnit, BusinessUnit."Data Source"::"Local Curr. (LCY)");
        Commit();
        REPORT.Run(REPORT::"Consolidation - Test Database", true, false, BusinessUnit);
    end;

    local procedure VerifyGLEntryAmount(DocNo: Code[20]; GLAccNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, GLAccNo, DocNo);
        GLEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyGLEntryAmountACY(DocNo: Code[20]; GLAccNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, GLAccNo, DocNo);
        GLEntry.TestField("Additional-Currency Amount", ExpectedAmount);
    end;

    local procedure PrepareTempDebitCreditGLEntries(var GLAccount: Record "G/L Account"; var GLEntry: Record "G/L Entry"; DebitAmount: Decimal; CreditAmount: Decimal): Decimal
    begin
        CreateGLAccountWithConsolidationSetup(GLAccount);
        MockGLEntry(GLEntry, GLAccount."No.", DebitAmount, 0);
        MockGLEntry(GLEntry, GLAccount."No.", 0, CreditAmount);
        exit(DebitAmount - CreditAmount);
    end;

    local procedure MockGLEntry(var GLEntry: Record "G/L Entry"; GLAccNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal)
    begin
        GLEntry.Init();
        GLEntry."Entry No." += 1;
        GLEntry."G/L Account No." := GLAccNo;
        GLEntry."Posting Date" := WorkDate;
        GLEntry.Amount := DebitAmount - CreditAmount;
        GLEntry."Debit Amount" := DebitAmount;
        GLEntry."Credit Amount" := CreditAmount;
        GLEntry.Insert();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConsolidationTestDatabaseReportHandler(var ConsolidationTestDatabase: TestRequestPage "Consolidation - Test Database")
    begin
        ConsolidationTestDatabase.StartingDate.SetValue(WorkDate);
        ConsolidationTestDatabase.EndingDate.SetValue(WorkDate);
        ConsolidationTestDatabase.CopyDimensions.SetValue(LibraryVariableStorage.DequeueText);
        ConsolidationTestDatabase.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConsolidatedTrialBalanceReportHandler(var ConsolidatedTrialBalance: TestRequestPage "Consolidated Trial Balance")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ImportConsolidationFromDBReportHandler(var ImportConsolidationfromDB: TestRequestPage "Import Consolidation from DB")
    begin
        ImportConsolidationfromDB.StartingDate.SetValue(WorkDate);
        ImportConsolidationfromDB.EndingDate.SetValue(WorkDate + 1);
        ImportConsolidationfromDB.DocumentNo.SetValue(LibraryRandom.RandInt(100));
        ImportConsolidationfromDB.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLConsolidationEliminationsRPH(var GLConsolidationEliminations: TestRequestPage "G/L Consolidation Eliminations")
    begin
        GLConsolidationEliminations.JournalTemplateName.SetValue(LibraryVariableStorage.DequeueText);
        GLConsolidationEliminations.JournalBatch.SetValue(LibraryVariableStorage.DequeueText);
        GLConsolidationEliminations.StartingDate.SetValue(WorkDate);
        GLConsolidationEliminations.EndingDate.SetValue(WorkDate);
        GLConsolidationEliminations.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

