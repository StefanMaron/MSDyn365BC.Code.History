#if not CLEAN18
codeunit 145005 "Foreign Currencies"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        DtldCustLedgEntriesErr: Label 'Detailed Customer Ledger Entry must not be exist.';
        DtldVendLedgEntriesErr: Label 'Detailed Vendor Ledger Entry must not be exist.';
        AmountErr: Label 'Amounts must be the same.';
        ExchRateWasAdjustedTxt: Label 'One or more currency exchange rates have been adjusted.';

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
    end;

    [Test]
    [HandlerFunctions('RequestPageAdjustExchangeRatesHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchangeRateSplitToCustomer()
    begin
        AdjustExchangeRateSplit(true, false);
    end;

    [Test]
    [HandlerFunctions('RequestPageAdjustExchangeRatesHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchangeRateSplitToVendor()
    begin
        AdjustExchangeRateSplit(false, true);
    end;

    local procedure AdjustExchangeRateSplit(AdjCust: Boolean; AdjVend: Boolean)
    var
        CurrencyCode: Code[10];
        CurrExchRateDate: array[2] of Date;
        DocumentNo: array[3] of Code[20];
    begin
        // 1. Setup
        Initialize;

        CurrExchRateDate[1] := WorkDate;
        CurrExchRateDate[2] := CalcDate('<1D>', CurrExchRateDate[1]);
        CurrencyCode := CreateCurrency(CurrExchRateDate);

        DocumentNo[1] := CreateCustomerLedgerEntries(CurrencyCode, CurrExchRateDate);
        DocumentNo[2] := CreateVendorLedgerEntries(CurrencyCode, CurrExchRateDate);
        DocumentNo[3] := GenerateDocumentNo(CurrExchRateDate[1]);

        // 2. Exercise
        RunAdjustExchangeRates(
          CurrencyCode, CurrExchRateDate[1], CurrExchRateDate[2], DocumentNo[3], AdjCust, AdjVend, false, true);

        // 3. Verify
        LibraryReportDataset.LoadDataSetFile;

        if AdjCust then
            LibraryReportDataset.AssertElementTagWithValueExists('CLEDocumentNo_Fld', DocumentNo[1])
        else
            LibraryReportDataset.AssertElementTagWithValueNotExist('CLEDocumentNo_Fld', DocumentNo[1]);

        if AdjVend then
            LibraryReportDataset.AssertElementTagWithValueExists('VLEDocumentNo_Fld', DocumentNo[2])
        else
            LibraryReportDataset.AssertElementTagWithValueNotExist('VLEDocumentNo_Fld', DocumentNo[2]);
    end;

    [Test]
    [HandlerFunctions('RequestPageAdjustExchangeRatesHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchangeRateTestReport()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        CurrencyCode: Code[10];
        CurrExchRateDate: array[2] of Date;
        DocumentNo: Code[20];
    begin
        // 1. Setup
        Initialize;

        CurrExchRateDate[1] := WorkDate;
        CurrExchRateDate[2] := CalcDate('<1D>', CurrExchRateDate[1]);
        CurrencyCode := CreateCurrency(CurrExchRateDate);

        CreateCustomerLedgerEntries(CurrencyCode, CurrExchRateDate);
        CreateVendorLedgerEntries(CurrencyCode, CurrExchRateDate);
        DocumentNo := GenerateDocumentNo(CurrExchRateDate[1]);

        // 2. Exercise
        RunAdjustExchangeRates(
          CurrencyCode, CurrExchRateDate[1], CurrExchRateDate[2], DocumentNo, true, true, false, true);

        // 3. Verify
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementTagWithValueExists('TestModeVar', 'true');

        DetailedCustLedgEntry.Reset();
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Unrealized Loss");
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        Assert.IsFalse(DetailedCustLedgEntry.FindFirst, DtldCustLedgEntriesErr);

        DetailedVendLedgEntry.Reset();
        DetailedVendLedgEntry.SetRange("Entry Type", DetailedVendLedgEntry."Entry Type"::"Unrealized Gain");
        DetailedVendLedgEntry.SetRange("Document No.", DocumentNo);
        Assert.IsFalse(DetailedVendLedgEntry.FindFirst, DtldVendLedgEntriesErr);
    end;

    [Test]
    [HandlerFunctions('RequestPageAdjustExchangeRatesHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatePostingByEntries()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        CurrencyCode: Code[10];
        CurrExchRateDate: array[2] of Date;
        DocumentNo: Code[20];
    begin
        // 1. Setup
        Initialize;

        CurrExchRateDate[1] := WorkDate;
        CurrExchRateDate[2] := CalcDate('<1D>', CurrExchRateDate[1]);
        CurrencyCode := CreateCurrency(CurrExchRateDate);

        CreateCustomerLedgerEntries(CurrencyCode, CurrExchRateDate);
        CreateVendorLedgerEntries(CurrencyCode, CurrExchRateDate);
        DocumentNo := GenerateDocumentNo(CurrExchRateDate[1]);

        // 2. Exercise
        RunAdjustExchangeRates(
          CurrencyCode, CurrExchRateDate[1], CurrExchRateDate[2], DocumentNo, true, true, false, false);

        // 3. Verify
        DetailedCustLedgEntry.Reset();
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Unrealized Loss");
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.FindFirst;

        DetailedVendLedgEntry.Reset();
        DetailedVendLedgEntry.SetRange("Entry Type", DetailedVendLedgEntry."Entry Type"::"Unrealized Gain");
        DetailedVendLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendLedgEntry.FindFirst;
    end;

    [Test]
    [HandlerFunctions('RequestPageAdjustExchangeRatesHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchangeRateIncrementalPosting()
    var
        CurrExchRate: Record "Currency Exchange Rate";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        CurrExchRateDate: array[2] of Date;
        DocumentNo: Code[20];
        Amount: Decimal;
        ExchRateAmount: Decimal;
        OriginalAmountLCY: Decimal;
    begin
        // 1. Setup
        Initialize;

        CurrExchRateDate[1] := WorkDate;
        CurrExchRateDate[2] := CalcDate('<1D>', CurrExchRateDate[1]);
        CurrencyCode := LibraryERM.CreateCurrencyWithGLAccountSetup;
        ExchRateAmount := LibraryRandom.RandDec(1, 2);
        LibraryERM.CreateExchangeRate(CurrencyCode, CurrExchRateDate[1], ExchRateAmount, ExchRateAmount);

        Amount := LibraryRandom.RandDec(1000, 2);

        LibraryERM.SelectGenJnlBatch(GenJnlBatch);

        // create and post invoice
        DocumentNo := CreateJournalLine(
            GenJnlLine, GenJnlBatch, GenJnlLine."Document Type"::Invoice,
            GenJnlLine."Account Type"::Customer, LibrarySales.CreateCustomerNo,
            Amount, CurrExchRateDate[2], CurrencyCode);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        LibraryERM.CreateExchangeRate(CurrencyCode, CurrExchRateDate[2], ExchRateAmount * 2, ExchRateAmount * 2);
        Commit();

        // 2. Exercise
        RunAdjustExchangeRates(
          CurrencyCode, CurrExchRateDate[1], CurrExchRateDate[2], DocumentNo, true, false, false, false);

        // 3. Verify
        DetailedCustLedgEntry.Reset();
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Initial Entry");
        DetailedCustLedgEntry.SetRange("Document Type", DetailedCustLedgEntry."Document Type"::Invoice);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.FindFirst;
        OriginalAmountLCY := DetailedCustLedgEntry."Amount (LCY)";

        DetailedCustLedgEntry.Reset();
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Unrealized Loss");
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.FindFirst;
        Assert.AreEqual(
          (1 / CurrExchRate.GetCurrentCurrencyFactor(CurrencyCode)) * Amount,
          OriginalAmountLCY + DetailedCustLedgEntry."Amount (LCY)", AmountErr);
    end;

    local procedure CreateCurrency(CurrExchRateDate: array[2] of Date): Code[10]
    var
        CurrencyCode: Code[10];
        ExchRateAmount: Decimal;
    begin
        CurrencyCode := LibraryERM.CreateCurrencyWithGLAccountSetup;
        ExchRateAmount := LibraryRandom.RandDec(1, 2);
        LibraryERM.CreateExchangeRate(CurrencyCode, CurrExchRateDate[1], ExchRateAmount, ExchRateAmount);
        LibraryERM.CreateExchangeRate(CurrencyCode, CurrExchRateDate[2], ExchRateAmount * 2, ExchRateAmount * 2);
        exit(CurrencyCode);
    end;

    local procedure CreateCustomerLedgerEntries(CurrencyCode: Code[10]; PostingDate: array[2] of Date): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        exit(CreateLedgerEntries(
            GenJnlLine."Account Type"::Customer, LibrarySales.CreateCustomerNo, CurrencyCode, PostingDate));
    end;

    local procedure CreateVendorLedgerEntries(CurrencyCode: Code[10]; PostingDate: array[2] of Date): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        exit(CreateLedgerEntries(
            GenJnlLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo, CurrencyCode, PostingDate));
    end;

    local procedure CreateLedgerEntries(AccountType: Option; AccountNo: Code[20]; CurrencyCode: Code[10]; PostingDate: array[2] of Date): Code[20]
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        Amount := LibraryRandom.RandDec(1000, 2);

        if AccountType = GenJnlLine."Account Type"::Vendor then
            Amount := -Amount;

        LibraryERM.SelectGenJnlBatch(GenJnlBatch);

        // create and post invoice
        DocumentNo := CreateJournalLine(
            GenJnlLine, GenJnlBatch, GenJnlLine."Document Type"::Invoice,
            AccountType, AccountNo, Amount, PostingDate[1], CurrencyCode);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // create and post payment with first currency exchange rate
        CreateJournalLine(
          GenJnlLine, GenJnlBatch, GenJnlLine."Document Type"::Payment,
          AccountType, AccountNo, -Amount / 2, PostingDate[1], CurrencyCode);
        GenJnlLine.Validate("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type"::Invoice);
        GenJnlLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJnlLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // create and post payment with second currency exchange rate
        CreateJournalLine(
          GenJnlLine, GenJnlBatch, GenJnlLine."Document Type"::Payment,
          AccountType, AccountNo, -GenJnlLine.Amount - Amount, CalcDate('<+1D>', PostingDate[2]), CurrencyCode);
        GenJnlLine.Validate("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type"::Invoice);
        GenJnlLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJnlLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(DocumentNo);
    end;

    local procedure CreateJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Option; AccountType: Option; AccountNo: Code[20]; Amount: Decimal; PostingDate: Date; CurrencyCode: Code[10]): Code[20]
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          DocumentType,
          AccountType,
          AccountNo,
          Amount);

        // Update journal line currency
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate(Description, GenJournalLine."Document No.");
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);

        exit(GenJournalLine."Document No.");
    end;

    local procedure GenerateDocumentNo(PostingDate: Date): Code[20]
    begin
        exit(StrSubstNo('ADJSK%1%2', Date2DMY(PostingDate, 3), Date2DMY(PostingDate, 2)));
    end;

    local procedure RunAdjustExchangeRates(CurrencyCode: Code[10]; StartDate: Date; EndDate: Date; DocumentNo: Code[20]; AdjCust: Boolean; AdjVend: Boolean; AdjBank: Boolean; TestMode: Boolean)
    var
        Currency: Record Currency;
        AdjustExchangeRates: Report "Adjust Exchange Rates";
    begin
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(EndDate);
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(AdjCust);
        LibraryVariableStorage.Enqueue(AdjVend);
        LibraryVariableStorage.Enqueue(AdjBank);
        LibraryVariableStorage.Enqueue(TestMode);

        Currency.SetRange(Code, CurrencyCode);
        AdjustExchangeRates.SetTableView(Currency);
        AdjustExchangeRates.UseRequestPage(true);
        AdjustExchangeRates.Run;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageAdjustExchangeRatesHandler(var AdjustExchangeRates: TestRequestPage "Adjust Exchange Rates")
    var
        FieldValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldValue);
        AdjustExchangeRates.StartingDate.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        AdjustExchangeRates.EndingDate.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        AdjustExchangeRates.DocumentNo.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        AdjustExchangeRates.AdjCust.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        AdjustExchangeRates.AdjVend.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        AdjustExchangeRates.AdjBank.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        AdjustExchangeRates.TestMode.SetValue(FieldValue);
        AdjustExchangeRates.SaveAsXml(
          LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ExchRateWasAdjustedTxt, Message);
    end;
}

#endif