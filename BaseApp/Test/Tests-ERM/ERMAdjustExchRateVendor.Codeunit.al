codeunit 134081 "ERM Adjust Exch. Rate Vendor"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Exchange Rate] [Detailed Ledger Entry] [Purchase]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        AmountErrorMessage: Label '%1 must be %2 in \\%3 %4=%5.';
        ExchRateWasAdjustedTxt: Label 'One or more currency exchange rates have been adjusted.';

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRateWithHigherValue()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // Test Adjust Exchange Rate batch job after modifying Higher Exchange Rate and verify Unrealized Loss entry created
        // in Detailed Vendor Ledger Entry.
        Initialize;
        AdjustExchRateForVendor(LibraryRandom.RandInt(50), DetailedVendorLedgEntry."Entry Type"::"Unrealized Loss");
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRateWithLowerValue()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // Check that Adjust Exchange Rate batch job after Modify Higher Exchange Rate and verify Unrealized Gain entry created
        // in Detailed Vendor Ledger Entry.
        Initialize;
        AdjustExchRateForVendor(-LibraryRandom.RandInt(50), DetailedVendorLedgEntry."Entry Type"::"Unrealized Gain");
    end;

    local procedure AdjustExchRateForVendor(ExchRateAmount: Decimal; EntryType: Option)
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Amount: Decimal;
    begin
        // Setup: Create and Post General Journal Line and Modify Exchange Rate.
        CreateGeneralJnlLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        UpdateExchangeRate(CurrencyExchangeRate, GenJournalLine."Currency Code", ExchRateAmount);
        Amount :=
          GenJournalLine."Amount (LCY)" -
          (GenJournalLine.Amount * CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount");

        // Exercise: Run Adjust Exchange Rate Batch Job and calculate Realized Gain/Loss Amount.
        RunAdjustExchangeRate(GenJournalLine."Currency Code", GenJournalLine."Document No.");

        // Verify: Verify Detailed Ledger Entry for Unrealized Loss/Gain entry.
        VerifyDetailedVendorEntry(GenJournalLine."Document No.", GenJournalLine."Currency Code", -Amount, EntryType);
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRateForVendorTwiceGainsLosses()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        ExchRateAmt: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 253498] Run Adjust Exchange Rates report twice when currency is changed for vendor entries from gains to losses
        Initialize;

        // [GIVEN] Purchase Invoice with Amount = 39008 posted with exch.rate = 1,0887
        ExchRateAmt := LibraryRandom.RandDec(10, 2);
        CreateGeneralJnlLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Exch. rates is changed to 1,0541 and adjustment completed.
        Amount :=
          UpdateExchRateAndCalcGainLossAmt(
            GenJournalLine.Amount, GenJournalLine."Amount (LCY)", GenJournalLine."Currency Code", 2 * ExchRateAmt);
        RunAdjustExchangeRate(GenJournalLine."Currency Code", GenJournalLine."Document No.");

        // [GIVEN] Dtld. Vend. Ledger Entry is created with amount = -1176,09 for Unrealized Loss type
        VerifyDtldVLELoss(
          GenJournalLine."Document No.", GenJournalLine."Currency Code", -Amount);

        // [GIVEN] Exch. rates is changed to 1,0666
        Amount :=
          UpdateExchRateAndCalcGainLossAmt(
            GenJournalLine.Amount, GenJournalLine."Amount (LCY)", GenJournalLine."Currency Code", -ExchRateAmt);

        // [WHEN] Run report Adjust Exchange Rates second time
        RunAdjustExchangeRate(GenJournalLine."Currency Code", GenJournalLine."Document No.");

        // [THEN] Dtld. Vendor Ledger Entry is created with amount = 433,69 for Unrealized Gain type
        VerifyDtldVLEGain(
          GenJournalLine."Document No.", GenJournalLine."Currency Code", Amount);
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustExchRateForVendorTwiceLossesGains()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        ExchRateAmt: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 253498] Run Adjust Exchange Rates report twice when currency is changed for vendor entries from losses to gains
        Initialize;

        // [GIVEN] Purchase Invoice with Amount = 39008 posted with exch.rate = 1,0887
        ExchRateAmt := LibraryRandom.RandDec(10, 2);
        CreateGeneralJnlLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Exch. rates is changed to 1,0541 and adjustment completed.
        Amount :=
          UpdateExchRateAndCalcGainLossAmt(
            GenJournalLine.Amount, GenJournalLine."Amount (LCY)", GenJournalLine."Currency Code", -2 * ExchRateAmt);
        RunAdjustExchangeRate(GenJournalLine."Currency Code", GenJournalLine."Document No.");

        // [GIVEN] Dtld. Vend. Ledger Entry is created with amount = 1176,09 for Unrealized Gain type
        VerifyDtldVLEGain(
          GenJournalLine."Document No.", GenJournalLine."Currency Code", -Amount);

        // [GIVEN] Exch. rates is changed to 1,0666
        Amount :=
          UpdateExchRateAndCalcGainLossAmt(
            GenJournalLine.Amount, GenJournalLine."Amount (LCY)", GenJournalLine."Currency Code", ExchRateAmt);

        // [WHEN] Run report Adjust Exchange Rates second time
        RunAdjustExchangeRate(GenJournalLine."Currency Code", GenJournalLine."Document No.");

        // [THEN] Dtld. Vendor Ledger Entry is created with amount = -742,4 for Unrealized Loss type
        VerifyDtldVLELoss(
          GenJournalLine."Document No.", GenJournalLine."Currency Code", Amount);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdateGeneralPostingSetup;

        isInitialized := true;
        Commit();
    end;

    local procedure CreateGeneralJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Using Random value for Invoice Amount.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, CreateVendor, -LibraryRandom.RandIntInRange(500, 1000));
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CreateCurrency);
        Vendor.Modify();
        exit(Vendor."No.");
    end;

    local procedure RunAdjustExchangeRate(CurrencyCode: Code[10]; DocumentNo: Code[20])
    var
        Currency: Record Currency;
        AdjustExchangeRates: Report "Adjust Exchange Rates";
    begin
        Currency.SetRange(Code, CurrencyCode);
        AdjustExchangeRates.SetTableView(Currency);
        AdjustExchangeRates.InitializeRequest2(0D, WorkDate, 'Test', WorkDate, DocumentNo, true, false);
        AdjustExchangeRates.UseRequestPage(false);
        AdjustExchangeRates.Run;
    end;

    local procedure UpdateExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; ExchRateAmount: Decimal)
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst;
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount", CurrencyExchangeRate."Relational Exch. Rate Amount" + ExchRateAmount);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure VerifyDetailedVendorEntry(DocumentNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; EntryType: Option)
    var
        Currency: Record Currency;
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        Currency.Get(CurrencyCode);
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.SetRange("Entry Type", EntryType);
        DetailedVendorLedgEntry.FindFirst;
        DetailedVendorLedgEntry.TestField("Ledger Entry Amount", true);
        Assert.AreNearlyEqual(
          Amount, DetailedVendorLedgEntry."Amount (LCY)", Currency."Amount Rounding Precision", StrSubstNo(AmountErrorMessage,
            DetailedVendorLedgEntry.FieldCaption("Amount (LCY)"), Amount, DetailedVendorLedgEntry.TableCaption,
            DetailedVendorLedgEntry.FieldCaption("Entry No."), DetailedVendorLedgEntry."Entry No."));
    end;

    local procedure VerifyDtldVLEGain(DocumentNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        VerifyDetailedVendorEntry(DocumentNo, CurrencyCode, Amount, DetailedVendorLedgEntry."Entry Type"::"Unrealized Gain");
    end;

    local procedure VerifyDtldVLELoss(DocumentNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        VerifyDetailedVendorEntry(DocumentNo, CurrencyCode, Amount, DetailedVendorLedgEntry."Entry Type"::"Unrealized Loss");
    end;

    local procedure UpdateExchRateAndCalcGainLossAmt(Amount: Decimal; AmountLCY: Decimal; CurrencyCode: Code[10]; ExchRateAmount: Decimal): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        UpdateExchangeRate(CurrencyExchangeRate, CurrencyCode, ExchRateAmount);
        exit(
          AmountLCY -
          Amount * CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount");
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ExchRateWasAdjustedTxt, Message);
    end;
}

