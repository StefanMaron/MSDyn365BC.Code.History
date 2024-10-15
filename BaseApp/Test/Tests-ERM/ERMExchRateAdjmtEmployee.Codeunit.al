codeunit 134884 "ERM Exch. Rate Adjmt. Employee"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Exchange Rate] [Detailed Ledger Entry] [Purchase]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        AmountMismatchErr: Label '%1 field must be %2 in %3 table for %4 field %5.';

    local procedure AdjustExchRateForEmployee(ExchRateAmount: Decimal; EntryType: Enum "Detailed CV Ledger Entry Type")
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
        LibraryERM.RunExchRateAdjustmentForDocNo(GenJournalLine."Currency Code", GenJournalLine."Document No.");

        // Verify: Verify Detailed Ledger Entry for Unrealized Loss/Gain entry.
        VerifyDetailedEmployeeEntry(GenJournalLine."Document No.", GenJournalLine."Currency Code", -Amount, EntryType);
        VerifyExchRateAdjmtLedgEntry("Exch. Rate Adjmt. Account Type"::Employee, GenJournalLine."Account No.");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Exch. Rate Adjmt. Employee");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Exch. Rate Adjmt. Employee");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        UpdateEmployeePostingGroup();
        isInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Exch. Rate Adjmt. Employee");
    end;

    local procedure CreateGeneralJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Using Random value for Invoice Amount.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Employee, CreateEmployee(), -LibraryRandom.RandIntInRange(500, 1000));
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateEmployee(): Code[20]
    var
        Employee: Record Employee;
        LibraryHR: Codeunit "Library - Human Resource";
    begin
        LibraryHR.CreateEmployeeWithBankAccount(Employee);
        Employee.Validate("Currency Code", CreateCurrency());
        Employee.Modify();
        exit(Employee."No.");
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure FindCurrencyExchRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10])
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
    end;

    local procedure UpdateExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; ExchRateAmount: Decimal)
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount", CurrencyExchangeRate."Relational Exch. Rate Amount" + ExchRateAmount);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure VerifyDetailedEmployeeEntry(DocumentNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        Currency: Record Currency;
        DetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
    begin
        Currency.Get(CurrencyCode);
        DetailedEmployeeLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedEmployeeLedgEntry.SetRange("Entry Type", EntryType);
        DetailedEmployeeLedgEntry.FindFirst();
        DetailedEmployeeLedgEntry.TestField("Ledger Entry Amount", true);
        DetailedEmployeeLedgEntry.CalcSums("Amount (LCY)");
        Assert.AreNearlyEqual(
            Amount, DetailedEmployeeLedgEntry."Amount (LCY)", Currency."Amount Rounding Precision",
            StrSubstNo(AmountMismatchErr,
                DetailedEmployeeLedgEntry.FieldCaption("Amount (LCY)"), Amount, DetailedEmployeeLedgEntry.TableCaption(),
                DetailedEmployeeLedgEntry.FieldCaption("Entry No."), DetailedEmployeeLedgEntry."Entry No."));
    end;

    local procedure VerifyExchRateAdjmtLedgEntry(AccountType: Enum "Exch. Rate Adjmt. Account Type"; AccountNo: Code[20])
    var
        DetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
        ExchRateAdjmtLedgEntry: Record "Exch. Rate Adjmt. Ledg. Entry";
    begin
        ExchRateAdjmtLedgEntry.SetRange("Account Type", AccountType);
        ExchRateAdjmtLedgEntry.SetRange("Account No.", AccountNo);
        ExchRateAdjmtLedgEntry.FindSet();
        repeat
            DetailedEmployeeLedgEntry.Get(ExchRateAdjmtLedgEntry."Detailed Ledger Entry No.");
            Assert.AreEqual(
                DetailedEmployeeLedgEntry."Amount (LCY)", ExchRateAdjmtLedgEntry."Adjustment Amount",
                StrSubstNo(AmountMismatchErr,
                    DetailedEmployeeLedgEntry.FieldCaption("Amount (LCY)"), ExchRateAdjmtLedgEntry."Adjustment Amount",
                    ExchRateAdjmtLedgEntry.TableCaption(), ExchRateAdjmtLedgEntry.FieldCaption("Register No."),
                    ExchRateAdjmtLedgEntry."Entry No."));
        until ExchRateAdjmtLedgEntry.Next() = 0;
    end;

    local procedure VerifyDtldVLEGain(DocumentNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    var
        DetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
    begin
        VerifyDetailedEmployeeEntry(DocumentNo, CurrencyCode, Amount, DetailedEmployeeLedgEntry."Entry Type"::"Unrealized Gain");
    end;

    local procedure VerifyDtldVLELoss(DocumentNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    var
        DetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
    begin
        VerifyDetailedEmployeeEntry(DocumentNo, CurrencyCode, Amount, DetailedEmployeeLedgEntry."Entry Type"::"Unrealized Loss");
    end;

    local procedure VerifyGLEntryForDocument(DocumentNo: Code[20]; AccountNo: Code[20]; EntryAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, AccountNo, GLEntry."Document Type"::" ");
        GLEntry.TestField(Amount, EntryAmount);
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

    local procedure UpdateEmployeePostingGroup()
    var
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        if EmployeePostingGroup.FindFirst() then
            if EmployeePostingGroup."Debit Rounding Account" = '' then begin
                EmployeePostingGroup.Validate("Debit Rounding Account", LibraryERM.CreateGLAccountNo());
                EmployeePostingGroup.Validate("Credit Rounding Account", LibraryERM.CreateGLAccountNo());
                EmployeePostingGroup.Validate("Debit Curr. Appln. Rndg. Acc.", LibraryERM.CreateGLAccountNo());
                EmployeePostingGroup.Validate("Credit Curr. Appln. Rndg. Acc.", LibraryERM.CreateGLAccountNo());
                EmployeePostingGroup.Modify();
            end;
    end;
}

