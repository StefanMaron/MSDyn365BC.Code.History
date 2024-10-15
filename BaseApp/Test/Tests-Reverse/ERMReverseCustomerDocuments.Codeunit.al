codeunit 134136 "ERM Reverse Customer Documents"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Reverse] [Detailed Ledger Entry] [Sales]
        IsInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        AmountError: Label '%1 must be %2 in %3, %4=%5.';

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Debit Amount LCY in Ledger Entries after Reversing Posted Invoice Entry for a Customer.
        Initialize();
        ReverseDebitDocument(GenJournalLine."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseFinanceChargeMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Debit Amount LCY in Ledger Entries after Reversing Posted Finance Charge Memo Entry for a Customer.
        Initialize();
        ReverseDebitDocument(GenJournalLine."Document Type"::"Finance Charge Memo");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseReminder()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Debit Amount LCY in Ledger Entries after Reversing Posted Reminder Entry for a Customer.
        Initialize();
        ReverseDebitDocument(GenJournalLine."Document Type"::Reminder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseRefund()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Debit Amount LCY in Ledger Entries after Reversing Posted Refund Entry for a Customer.
        Initialize();
        ReverseDebitDocument(GenJournalLine."Document Type"::Refund);
    end;

    local procedure ReverseDebitDocument(DocumentType: Enum "Gen. Journal Document Type")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DebitAmountLCY: Decimal;
    begin
        // Create a Customer, Currency and Post General Journal Line with a Random Positive Amount. Reverse the Posted Entry.
        GeneralLedgerSetup.Get();
        DebitAmountLCY := ReverseDocument(DetailedCustLedgEntry, DocumentType, LibraryRandom.RandDec(10, 2));

        // Verify: Verify Debit Amount LCY in Detailed Customer Ledger Entries.
        Assert.AreNearlyEqual(
          DebitAmountLCY, DetailedCustLedgEntry."Debit Amount (LCY)", GeneralLedgerSetup."Inv. Rounding Precision (LCY)",
          StrSubstNo(AmountError, DetailedCustLedgEntry.FieldCaption("Debit Amount (LCY)"), DebitAmountLCY,
            DetailedCustLedgEntry.TableCaption(), DetailedCustLedgEntry.FieldCaption("Entry No."), DetailedCustLedgEntry."Entry No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReversePayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Credit Amount LCY in Ledger Entries after Reversing Posted Payment Entry for a Customer.
        Initialize();
        ReverseCreditDocument(GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Credit Amount LCY in Ledger Entries after Reversing Posted Credit Memo Entry for a Customer.
        Initialize();
        ReverseCreditDocument(GenJournalLine."Document Type"::"Credit Memo");
    end;

    local procedure ReverseCreditDocument(DocumentType: Enum "Gen. Journal Document Type")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CreditAmountLCY: Decimal;
    begin
        // Create a Customer, Currency and Post General Journal Line with a Random Negative Amount. Reverse the Posted Entry.
        GeneralLedgerSetup.Get();
        CreditAmountLCY := -ReverseDocument(DetailedCustLedgEntry, DocumentType, -LibraryRandom.RandDec(10, 2));

        // Verify: Verify Credit Amount LCY in Detailed Customer Ledger Entries.
        Assert.AreNearlyEqual(
          CreditAmountLCY, DetailedCustLedgEntry."Credit Amount (LCY)", GeneralLedgerSetup."Inv. Rounding Precision (LCY)",
          StrSubstNo(AmountError, DetailedCustLedgEntry.FieldCaption("Credit Amount (LCY)"), CreditAmountLCY,
            DetailedCustLedgEntry.TableCaption(), DetailedCustLedgEntry.FieldCaption("Entry No."), DetailedCustLedgEntry."Entry No."));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Reverse Customer Documents");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Reverse Customer Documents");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Reverse Customer Documents");
    end;

    local procedure ReverseDocument(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal) AmountLCY: Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
    begin
        // Setup: Create Customer, Create Genenral Journal Line with different Document Types, new Currency and Post it.
        CreateGeneralJournalLine(GenJournalLine, DocumentType, Amount, CreateCurrency);
        AmountLCY := LibraryERM.ConvertCurrency(Amount, GenJournalLine."Currency Code", '', WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Reverse posted Transaction.
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");

        // Find Detailed Customer Ledger Entry to verify Debit Amount(LCY) or Credit Amount (LCY).
        FindDtldCustomerLedgerEntries(DetailedCustLedgEntry, GenJournalLine."Document No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; CurrencyCode: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, Customer."No.", Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure FindDtldCustomerLedgerEntries(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DocumentNo: Code[20])
    begin
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.FindLast();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Confirm Handler.
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;
}

