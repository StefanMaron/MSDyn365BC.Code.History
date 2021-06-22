codeunit 132570 "Credit Transfer Register UT"
{
    Subtype = Test;
    Permissions = TableData "Employee Ledger Entry" = rimd;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Credit Transfer] [UT]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPaymentExport: Codeunit "Library - Payment Export";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        UnexpectedCTEntryErr: Label 'Unexpected credit transfer entry shown.';
        UnexpectedIBANErr: Label 'Unexpected creditor IBAN shown.';
        UnexpectedMsgToCreditorErr: Label 'Unexpected message to creditor shown.';
        LibraryHumanResource: Codeunit "Library - Human Resource";
        IsInitialized: Boolean;
        UnexpectedAmountErr: Label 'Unexpected transfer amount shown.';

    [Test]
    [Scope('OnPrem')]
    procedure TestCancellingCreditTransferRegister()
    var
        BankAcc: Record "Bank Account";
        CreditTransferEntry: Record "Credit Transfer Entry";
        CreditTransferRegister: Record "Credit Transfer Register";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        Initialize;
        PreSetup(BankAcc, Vendor, VendorBankAccount, GenJnlLine);

        // Setup
        CreditTransferRegister.CreateNew(LibraryUtility.GenerateGUID, BankAcc."No.");
        CreditTransferRegister.FindLast;
        CreditTransferEntry.CreateNew(CreditTransferRegister."No.", 1,
          GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine.GetAppliesToDocEntryNo,
          GenJnlLine."Posting Date", GenJnlLine."Currency Code", GenJnlLine.Amount / 2, '',
          GenJnlLine."Recipient Bank Account", GenJnlLine."Message to Recipient");
        CreditTransferEntry.CreateNew(CreditTransferRegister."No.", 2,
          GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine.GetAppliesToDocEntryNo,
          GenJnlLine."Posting Date", GenJnlLine."Currency Code", GenJnlLine.Amount / 2, '',
          GenJnlLine."Recipient Bank Account", GenJnlLine."Message to Recipient");

        // Exercise
        CreditTransferRegister.Validate(Status, CreditTransferRegister.Status::"File Created");
        CreditTransferRegister.Modify();

        // Verify
        CreditTransferEntry.SetRange("Credit Transfer Register No.", CreditTransferRegister."No.");
        CreditTransferEntry.SetAutoCalcFields(Canceled);
        CreditTransferEntry.FindSet;
        repeat
            CreditTransferEntry.TestField(Canceled, false);
        until CreditTransferEntry.Next = 0;

        // Exercise
        CreditTransferRegister.Validate(Status, CreditTransferRegister.Status::Canceled);
        CreditTransferRegister.Modify();

        // Verify
        CreditTransferEntry.FindSet;
        repeat
            CreditTransferEntry.TestField(Canceled, true);
        until CreditTransferEntry.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestShowCTEntriesForGenJnlLine()
    var
        BankAcc: Record "Bank Account";
        CreditTransferEntry: Record "Credit Transfer Entry";
        CreditTransferRegister: Record "Credit Transfer Register";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        CreditTransferRegEntries: TestPage "Credit Transfer Reg. Entries";
        CTEntryNo: Integer;
        CTEntryMessageToRecipient1: Text[70];
        CTEntryMessageToRecipient2: Text[70];
    begin
        // Verify that after invoking codeunit "Gen. Jnl.-Show CT Entries" on a General Journal Line,
        // corresponding credit transfer register entries are shown, by checking their entry no.
        // Explicitly verify that message to recipient and vendor bank account IBAN are shown in the credit transfer entries

        Initialize;
        PreSetup(BankAcc, Vendor, VendorBankAccount, GenJnlLine);

        // Setup
        CTEntryNo := LibraryRandom.RandInt(1000);
        CTEntryMessageToRecipient1 := CopyStr(LibraryUtility.GenerateRandomText(70), 1, 70);
        CTEntryMessageToRecipient2 := CopyStr(LibraryUtility.GenerateRandomText(70), 1, 70);
        CreditTransferRegister.CreateNew(LibraryUtility.GenerateGUID, BankAcc."No.");
        CreditTransferEntry.CreateNew(CreditTransferRegister."No.", CTEntryNo,
          GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine."Source Line No.",
          GenJnlLine."Posting Date", GenJnlLine."Currency Code", GenJnlLine.Amount / 2, '',
          GenJnlLine."Recipient Bank Account", CTEntryMessageToRecipient1);
        CreditTransferEntry.CreateNew(CreditTransferRegister."No.", CTEntryNo + 1,
          GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine."Source Line No.",
          GenJnlLine."Posting Date", GenJnlLine."Currency Code", GenJnlLine.Amount / 2, '',
          GenJnlLine."Recipient Bank Account", CTEntryMessageToRecipient2);
        CreditTransferRegister.Validate(Status, CreditTransferRegister.Status::"File Created");
        CreditTransferRegister.Modify();

        // Verify that corresponding credit transfer register entries are shown, by checking the entry no.
        // Explicitly verify that message to recipient and vendor bank account IBAN are shown
        CreditTransferRegEntries.Trap;
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Show CT Entries", GenJnlLine);
        CreditTransferRegEntries.First;
        Assert.AreEqual(CTEntryNo, CreditTransferRegEntries."Entry No.".AsInteger, UnexpectedCTEntryErr);
        Assert.AreEqual(CTEntryMessageToRecipient1, CreditTransferRegEntries."Message to Recipient".Value, UnexpectedMsgToCreditorErr);
        Assert.AreEqual(VendorBankAccount.IBAN, CreditTransferRegEntries.RecipientIBAN.Value, UnexpectedIBANErr);
        Assert.AreNearlyEqual(GenJnlLine.Amount / 2, CreditTransferRegEntries."Transfer Amount".AsDEcimal,
          LibraryERM.GetAmountRoundingPrecision, UnexpectedAmountErr);
        CreditTransferRegEntries.Next;
        Assert.AreEqual(CTEntryNo + 1, CreditTransferRegEntries."Entry No.".AsInteger, UnexpectedCTEntryErr);
        Assert.AreEqual(CTEntryMessageToRecipient2, CreditTransferRegEntries."Message to Recipient".Value, UnexpectedMsgToCreditorErr);
        Assert.AreEqual(VendorBankAccount.IBAN, CreditTransferRegEntries.RecipientIBAN.Value, UnexpectedIBANErr);
        Assert.AreNearlyEqual(GenJnlLine.Amount / 2, CreditTransferRegEntries."Transfer Amount".AsDEcimal,
          LibraryERM.GetAmountRoundingPrecision, UnexpectedAmountErr);
        Assert.IsFalse(CreditTransferRegEntries.Next, UnexpectedCTEntryErr);
        CreditTransferRegEntries.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestShowCTEntriesForCustomerRefund()
    var
        BankAcc: Record "Bank Account";
        CreditTransferEntry: Record "Credit Transfer Entry";
        CreditTransferRegister: Record "Credit Transfer Register";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        CreditTransferRegEntries: TestPage "Credit Transfer Reg. Entries";
        CTEntryNo: Integer;
    begin
        // Verify that after invoking codeunit "Gen. Jnl.-Show CT Entries" on a General Journal Line for a customer refund,
        // corresponding credit transfer register entries are shown, by checking their entry no.
        // Explicitly verify that message to recipient and customer bank account IBAN are shown in the credit transfer entries

        Initialize;

        // Pre-Setup
        LibraryERM.CreateBankAccount(BankAcc);
        CreateExportGenJournalBatch(GenJnlBatch, BankAcc."No.");

        LibrarySales.CreateCustomer(Customer);
        CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");

        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Refund,
          GenJnlLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(100, 2));
        GenJnlLine."Recipient Bank Account" := CustomerBankAccount.Code;
        GenJnlLine.Modify();

        // Setup
        CTEntryNo := LibraryRandom.RandInt(1000);
        CreditTransferRegister.CreateNew(LibraryUtility.GenerateGUID, BankAcc."No.");
        CreditTransferEntry.CreateNew(CreditTransferRegister."No.", CTEntryNo,
          GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine."Source Line No.",
          GenJnlLine."Posting Date", GenJnlLine."Currency Code", GenJnlLine.Amount, '',
          GenJnlLine."Recipient Bank Account", '');
        CreditTransferRegister.Validate(Status, CreditTransferRegister.Status::"File Created");
        CreditTransferRegister.Modify();

        // Verify that corresponding credit transfer register entries are shown, by checking the entry no.
        // Explicitly verify that message to recipient and vendor bank account IBAN are shown
        CreditTransferRegEntries.Trap;
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Show CT Entries", GenJnlLine);
        CreditTransferRegEntries.First;
        Assert.AreEqual(CTEntryNo, CreditTransferRegEntries."Entry No.".AsInteger, UnexpectedCTEntryErr);
        Assert.AreEqual(CustomerBankAccount.IBAN, CreditTransferRegEntries.RecipientIBAN.Value, UnexpectedIBANErr);
        Assert.AreEqual(GenJnlLine.Amount, CreditTransferRegEntries."Transfer Amount".AsDEcimal, UnexpectedAmountErr);
        Assert.IsFalse(CreditTransferRegEntries.Next, UnexpectedCTEntryErr);
        CreditTransferRegEntries.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestShowCTEntriesForEmployee()
    var
        BankAcc: Record "Bank Account";
        CreditTransferEntry: Record "Credit Transfer Entry";
        CreditTransferRegister: Record "Credit Transfer Register";
        GenJnlLine: Record "Gen. Journal Line";
        Employee: Record Employee;
        CreditTransferRegEntries: TestPage "Credit Transfer Reg. Entries";
        CTEntryNo: Integer;
        CTEntryMessageToRecipient1: Text[70];
        CTEntryMessageToRecipient2: Text[70];
    begin
        // Verify that after invoking codeunit "Gen. Jnl.-Show CT Entries" on a General Journal Line,
        // corresponding credit transfer register entries are shown, by checking their entry no.
        // Explicitly verify that message to recipient and vendor bank account IBAN are shown in the credit transfer entries

        Initialize;
        PreSetupForEmployee(BankAcc, Employee, GenJnlLine);

        // Setup
        CTEntryNo := LibraryRandom.RandInt(1000);
        CreditTransferRegister.CreateNew(LibraryUtility.GenerateGUID, BankAcc."No.");
        CTEntryMessageToRecipient1 := CopyStr(LibraryUtility.GenerateRandomText(70), 1, 70);
        CreditTransferEntry.CreateNew(CreditTransferRegister."No.", CTEntryNo,
          GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine."Source Line No.",
          GenJnlLine."Posting Date", GenJnlLine."Currency Code", GenJnlLine.Amount / 2, '',
          GenJnlLine."Recipient Bank Account", CTEntryMessageToRecipient1);
        CTEntryMessageToRecipient2 := CopyStr(LibraryUtility.GenerateRandomText(70), 1, 70);
        CreditTransferEntry.CreateNew(CreditTransferRegister."No.", CTEntryNo + 1,
          GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine."Source Line No.",
          GenJnlLine."Posting Date", GenJnlLine."Currency Code", GenJnlLine.Amount / 2, '',
          GenJnlLine."Recipient Bank Account", CTEntryMessageToRecipient2);
        CreditTransferRegister.Validate(Status, CreditTransferRegister.Status::"File Created");
        CreditTransferRegister.Modify();

        // Verify that corresponding credit transfer register entries are shown, by checking the entry no.
        // Explicitly verify that message to recipient and vendor bank account IBAN are shown
        CreditTransferRegEntries.Trap;
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Show CT Entries", GenJnlLine);
        CreditTransferRegEntries.First;
        Assert.AreEqual(CTEntryMessageToRecipient1, CreditTransferRegEntries."Message to Recipient".Value, UnexpectedMsgToCreditorErr);
        Assert.AreEqual(CTEntryNo, CreditTransferRegEntries."Entry No.".AsInteger, UnexpectedCTEntryErr);
        Assert.AreNearlyEqual(GenJnlLine.Amount / 2, CreditTransferRegEntries."Transfer Amount".AsDEcimal,
          LibraryERM.GetAmountRoundingPrecision, UnexpectedAmountErr);
        Assert.AreEqual(Employee.IBAN, CreditTransferRegEntries.RecipientIBAN.Value, UnexpectedIBANErr);
        CreditTransferRegEntries.Next;
        Assert.AreEqual(CTEntryNo + 1, CreditTransferRegEntries."Entry No.".AsInteger, UnexpectedCTEntryErr);
        Assert.AreEqual(Employee.IBAN, CreditTransferRegEntries.RecipientIBAN.Value, UnexpectedIBANErr);
        Assert.AreEqual(CTEntryMessageToRecipient2, CreditTransferRegEntries."Message to Recipient".Value, UnexpectedMsgToCreditorErr);
        Assert.AreNearlyEqual(GenJnlLine.Amount / 2, CreditTransferRegEntries."Transfer Amount".AsDEcimal,
          LibraryERM.GetAmountRoundingPrecision, UnexpectedAmountErr);
        Assert.IsFalse(CreditTransferRegEntries.Next, UnexpectedCTEntryErr);
        CreditTransferRegEntries.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTotalExportedAmountForGenJnlLine()
    var
        BankAcc: Record "Bank Account";
        CreditTransferEntry: Record "Credit Transfer Entry";
        CreditTransferRegister: Record "Credit Transfer Register";
        CreditTransferRegister2: Record "Credit Transfer Register";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CTEntryNo: Integer;
        CTEntry1Amount: Decimal;
        CTEntry2Amount: Decimal;
        CTEntry3Amount: Decimal;
    begin
        // Verify that flow field "Total Exported Amount" on General Journal Line, shows
        // the sum of Transfer Amount values from
        // all non-cancelled Credit Transfer Register Entries for that General journal Line

        Initialize;
        PreSetup(BankAcc, Vendor, VendorBankAccount, GenJnlLine);
        CTEntry1Amount := GenJnlLine.Amount / 2;
        CTEntry2Amount := GenJnlLine.Amount / 4;
        CTEntry3Amount := GenJnlLine.Amount / 8;

        // Setup
        // Create three CT Entries in two CT Registers, one of which is cancelled, and the other one exported to file
        CTEntryNo := LibraryRandom.RandInt(1000);
        GeneralLedgerSetup.Get();
        CreditTransferEntry.SetAutoCalcFields(Canceled);
        CreditTransferRegister.CreateNew(LibraryUtility.GenerateGUID, BankAcc."No.");
        CreditTransferEntry.CreateNew(CreditTransferRegister."No.", CTEntryNo,
          GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine."Source Line No.",
          GenJnlLine."Posting Date", GeneralLedgerSetup.GetCurrencyCode(GenJnlLine."Currency Code"), CTEntry1Amount, '',
          GenJnlLine."Recipient Bank Account", '');
        CreditTransferEntry.CreateNew(CreditTransferRegister."No.", CTEntryNo + 1,
          GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine."Source Line No.",
          GenJnlLine."Posting Date", GeneralLedgerSetup.GetCurrencyCode(GenJnlLine."Currency Code"), CTEntry2Amount, '',
          GenJnlLine."Recipient Bank Account", '');
        CreditTransferRegister.Validate(Status, CreditTransferRegister.Status::"File Created");
        CreditTransferRegister.Modify();

        CreditTransferRegister2.CreateNew(LibraryUtility.GenerateGUID, BankAcc."No.");
        CreditTransferEntry.CreateNew(CreditTransferRegister2."No.", CTEntryNo + 2,
          GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine."Source Line No.",
          GenJnlLine."Posting Date", GeneralLedgerSetup.GetCurrencyCode(GenJnlLine."Currency Code"), CTEntry3Amount, '',
          GenJnlLine."Recipient Bank Account", '');
        CreditTransferRegister2.Validate(Status, CreditTransferRegister2.Status::Canceled);
        CreditTransferRegister2.Modify();

        Assert.AreNearlyEqual(CTEntry1Amount + CTEntry2Amount, GenJnlLine.TotalExportedAmount,
          LibraryERM.GetAmountRoundingPrecision, 'Total Exported Amount wrongly calculated.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTotalExportedAmountForGenJnlLineForEmployee()
    var
        BankAcc: Record "Bank Account";
        CreditTransferEntry: Record "Credit Transfer Entry";
        CreditTransferRegister: Record "Credit Transfer Register";
        CreditTransferRegister2: Record "Credit Transfer Register";
        GenJnlLine: Record "Gen. Journal Line";
        Employee: Record Employee;
        GeneralLedgerSetup: Record "General Ledger Setup";
        CTEntryNo: Integer;
        CTEntry1Amount: Decimal;
        CTEntry2Amount: Decimal;
        CTEntry3Amount: Decimal;
    begin
        // Verify that flow field "Total Exported Amount" on General Journal Line, shows
        // the sum of Transfer Amount values from
        // all non-cancelled Credit Transfer Register Entries for that General journal Line

        Initialize;
        PreSetupForEmployee(BankAcc, Employee, GenJnlLine);
        CTEntry1Amount := GenJnlLine.Amount / 2;
        CTEntry2Amount := GenJnlLine.Amount / 4;
        CTEntry3Amount := GenJnlLine.Amount / 8;

        // Setup
        // Create three CT Entries in two CT Registers, one of which is cancelled, and the other one exported to file
        CreditTransferEntry.SetAutoCalcFields(Canceled);
        GeneralLedgerSetup.Get();
        CreditTransferRegister.CreateNew(LibraryUtility.GenerateGUID, BankAcc."No.");
        CTEntryNo := LibraryRandom.RandInt(1000);
        CreditTransferEntry.CreateNew(CreditTransferRegister."No.", CTEntryNo,
          GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine."Source Line No.",
          GenJnlLine."Posting Date", GeneralLedgerSetup.GetCurrencyCode(GenJnlLine."Currency Code"), CTEntry1Amount, '',
          GenJnlLine."Recipient Bank Account", '');
        CreditTransferEntry.CreateNew(CreditTransferRegister."No.", CTEntryNo + 1,
          GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine."Source Line No.",
          GenJnlLine."Posting Date", GeneralLedgerSetup.GetCurrencyCode(GenJnlLine."Currency Code"), CTEntry2Amount, '',
          GenJnlLine."Recipient Bank Account", '');

        CreditTransferRegister2.CreateNew(LibraryUtility.GenerateGUID, BankAcc."No.");
        CreditTransferEntry.CreateNew(CreditTransferRegister2."No.", CTEntryNo + 2,
          GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine."Source Line No.",
          GenJnlLine."Posting Date", GeneralLedgerSetup.GetCurrencyCode(GenJnlLine."Currency Code"), CTEntry3Amount, '',
          GenJnlLine."Recipient Bank Account", '');
        CreditTransferRegister.Validate(Status, CreditTransferRegister.Status::"File Created");
        CreditTransferRegister.Modify();
        CreditTransferRegister2.Validate(Status, CreditTransferRegister2.Status::Canceled);
        CreditTransferRegister2.Modify();

        Assert.AreNearlyEqual(CTEntry1Amount + CTEntry2Amount, GenJnlLine.TotalExportedAmount,
          LibraryERM.GetAmountRoundingPrecision, 'Total Exported Amount wrongly calculated.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTotalExportedAmountForGenJnlLineWithoutInvoiceNo()
    var
        BankAcc: Record "Bank Account";
        CreditTransferEntry: Record "Credit Transfer Entry";
        CreditTransferRegister: Record "Credit Transfer Register";
        CreditTransferRegister2: Record "Credit Transfer Register";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CTEntryNo: Integer;
        CTEntry1Amount: Decimal;
        CTEntry2Amount: Decimal;
        CTEntry3Amount: Decimal;
    begin
        // Verify that flow field "Total Exported Amount" on General Journal Line, shows
        // the sum of Transfer Amount values from
        // all non-cancelled Credit Transfer Register Entries for that General journal Line

        Initialize;
        PreSetup(BankAcc, Vendor, VendorBankAccount, GenJnlLine);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine2,
          GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", GenJnlLine2."Document Type"::Payment,
          GenJnlLine2."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));
        LibraryERM.CreateCurrency(Currency);
        GenJnlLine2."Currency Code" := Currency.Code;
        GenJnlLine2.Modify();
        CTEntry1Amount := GenJnlLine2.Amount / 2;
        CTEntry2Amount := GenJnlLine2.Amount / 4;
        CTEntry3Amount := GenJnlLine2.Amount / 8;

        // Setup
        // Create three CT Entries in two CT Registers, one of which is cancelled, and the other one exported to file
        CreditTransferEntry.SetAutoCalcFields(Canceled);
        CreditTransferRegister.CreateNew(LibraryUtility.GenerateGUID, BankAcc."No.");
        GeneralLedgerSetup.Get();
        CTEntryNo := LibraryRandom.RandInt(1000);
        CreditTransferEntry.CreateNew(CreditTransferRegister."No.", CTEntryNo,
          GenJnlLine2."Account Type", GenJnlLine."Account No.", GenJnlLine2."Source Line No.",
          GenJnlLine2."Posting Date", GeneralLedgerSetup.GetCurrencyCode(GenJnlLine2."Currency Code"), CTEntry1Amount, '',
          GenJnlLine2."Recipient Bank Account", '');
        CreditTransferEntry.CreateNew(CreditTransferRegister."No.", CTEntryNo + 1,
          GenJnlLine2."Account Type", GenJnlLine2."Account No.", GenJnlLine2."Source Line No.",
          GenJnlLine2."Posting Date", GeneralLedgerSetup.GetCurrencyCode(GenJnlLine2."Currency Code"), CTEntry2Amount, '',
          GenJnlLine2."Recipient Bank Account", '');
        CreditTransferRegister.Validate(Status, CreditTransferRegister.Status::"File Created");
        CreditTransferRegister.Modify();

        CreditTransferRegister2.CreateNew(LibraryUtility.GenerateGUID, BankAcc."No.");
        CreditTransferEntry.CreateNew(CreditTransferRegister2."No.", CTEntryNo + 2,
          GenJnlLine2."Account Type", GenJnlLine."Account No.", GenJnlLine2."Source Line No.",
          GenJnlLine2."Posting Date", GeneralLedgerSetup.GetCurrencyCode(GenJnlLine."Currency Code"), CTEntry3Amount, '',
          GenJnlLine2."Recipient Bank Account", '');
        CreditTransferRegister2.Validate(Status, CreditTransferRegister2.Status::Canceled);
        CreditTransferRegister2.Modify();

        Assert.AreNearlyEqual(CTEntry1Amount + CTEntry2Amount, GenJnlLine2.TotalExportedAmount,
          LibraryERM.GetAmountRoundingPrecision, 'Total Exported Amount wrongly calculated.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTotalExportedAmountForGenJnlLineWithDeletedAppliesToInvoiceNo()
    var
        BankAcc: Record "Bank Account";
        CreditTransferEntry: Record "Credit Transfer Entry";
        CreditTransferRegister: Record "Credit Transfer Register";
        CreditTransferRegister2: Record "Credit Transfer Register";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CTEntryNo: Integer;
        CTEntry1Amount: Decimal;
        CTEntry2Amount: Decimal;
        CTEntry3Amount: Decimal;
    begin
        // Verification for the fix for
        // Bug 108836: The field Total Exported Amount in the Payment Journal shows incorrect values when used deletes
        Initialize;
        PreSetup(BankAcc, Vendor, VendorBankAccount, GenJnlLine);
        // simulate the user manually setting "Applies-to Doc. No." to blank
        GenJnlLine."Applies-to Doc. No." := '';
        GenJnlLine.Modify();

        LibraryERM.CreateCurrency(Currency);
        CTEntry1Amount := GenJnlLine.Amount / 2;
        CTEntry2Amount := GenJnlLine.Amount / 4;
        CTEntry3Amount := GenJnlLine.Amount / 8;

        // Setup
        // Create three CT Entries in two CT Registers, one of which is cancelled, and the other one exported to file
        CTEntryNo := LibraryRandom.RandInt(1000);
        GeneralLedgerSetup.Get();
        CreditTransferEntry.SetAutoCalcFields(Canceled);
        CreditTransferRegister.CreateNew(LibraryUtility.GenerateGUID, BankAcc."No.");
        CreditTransferEntry.CreateNew(CreditTransferRegister."No.", CTEntryNo,
          GenJnlLine."Account Type", GenJnlLine."Account No.", 0,
          GenJnlLine."Posting Date", GeneralLedgerSetup.GetCurrencyCode(GenJnlLine."Currency Code"), CTEntry1Amount, '',
          GenJnlLine."Recipient Bank Account", '');
        CreditTransferEntry.CreateNew(CreditTransferRegister."No.", CTEntryNo + 1,
          GenJnlLine."Account Type", GenJnlLine."Account No.", 0,
          GenJnlLine."Posting Date", GeneralLedgerSetup.GetCurrencyCode(GenJnlLine."Currency Code"), CTEntry2Amount, '',
          GenJnlLine."Recipient Bank Account", '');
        CreditTransferRegister.Validate(Status, CreditTransferRegister.Status::"File Created");
        CreditTransferRegister.Modify();

        CreditTransferRegister2.CreateNew(LibraryUtility.GenerateGUID, BankAcc."No.");
        CreditTransferEntry.CreateNew(CreditTransferRegister2."No.", CTEntryNo + 2,
          GenJnlLine."Account Type", GenJnlLine."Account No.", 0,
          GenJnlLine."Posting Date", GeneralLedgerSetup.GetCurrencyCode(GenJnlLine."Currency Code"), CTEntry3Amount, '',
          GenJnlLine."Recipient Bank Account", '');
        CreditTransferRegister2.Validate(Status, CreditTransferRegister2.Status::Canceled);
        CreditTransferRegister2.Modify();

        Assert.AreNearlyEqual(CTEntry1Amount + CTEntry2Amount, GenJnlLine.TotalExportedAmount,
          LibraryERM.GetAmountRoundingPrecision, 'Total Exported Amount wrongly calculated.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestShowCancelledCTEntriesForGenJnlLine()
    var
        BankAcc: Record "Bank Account";
        CreditTransferEntry: Record "Credit Transfer Entry";
        CreditTransferRegister: Record "Credit Transfer Register";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        CreditTransferRegEntries: TestPage "Credit Transfer Reg. Entries";
        CTEntryNo: Integer;
    begin
        // Verify that after invoking codeunit "Gen. Jnl.-Show CT Entries" on a General Journal Line,
        // corresponding cancelled credit transfer register entries are not shown

        Initialize;
        PreSetup(BankAcc, Vendor, VendorBankAccount, GenJnlLine);

        // Setup
        CTEntryNo := LibraryRandom.RandInt(1000);
        CreditTransferRegister.CreateNew(LibraryUtility.GenerateGUID, BankAcc."No.");
        CreditTransferEntry.CreateNew(CreditTransferRegister."No.", CTEntryNo,
          GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine."Source Line No.",
          GenJnlLine."Posting Date", GenJnlLine."Currency Code", GenJnlLine.Amount / 2, '',
          GenJnlLine."Recipient Bank Account", '');
        CreditTransferRegister.Validate(Status, CreditTransferRegister.Status::Canceled);
        CreditTransferRegister.Modify();

        // Verify that corresponding credit transfer register entries are shown
        CreditTransferRegEntries.Trap;
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Show CT Entries", GenJnlLine);
        CreditTransferRegEntries.First;
        Assert.AreEqual(0, CreditTransferRegEntries."Entry No.".AsInteger, UnexpectedCTEntryErr);
        Assert.IsFalse(CreditTransferRegEntries.Next, UnexpectedCTEntryErr);
        CreditTransferRegEntries.Close;
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure TestExportedToFileFlagForGenJnlLine()
    var
        BankAcc: Record "Bank Account";
        CreditTransferEntry: Record "Credit Transfer Entry";
        CreditTransferRegister: Record "Credit Transfer Register";
        GenJnlLine: Record "Gen. Journal Line";
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CTEntryNo: Integer;
    begin
        // Verify that after you export a payment from General Journal Line,
        // the "Exported to Payment File" flag is set both on GenJnlLine and vendor ledger entry

        Initialize;

        // Pre-Setup
        PreSetup(BankAcc, Vendor, VendorBankAccount, GenJnlLine);

        // Setup
        // Create three CT Entries in two CT Registers, one of which is cancelled, and the other one exported to file
        CTEntryNo := LibraryRandom.RandInt(1000);
        CreditTransferEntry.SetAutoCalcFields(Canceled);
        CreditTransferRegister.CreateNew(LibraryUtility.GenerateGUID, BankAcc."No.");
        CreditTransferEntry.CreateNew(CreditTransferRegister."No.", CTEntryNo,
          GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine."Source Line No.",
          GenJnlLine."Posting Date", GenJnlLine."Currency Code", GenJnlLine.Amount, '',
          GenJnlLine."Recipient Bank Account", '');

        // Pre-Exercise
        DataExch.Init();
        DataExch.Insert();
        GenJnlLine."Data Exch. Entry No." := DataExch."Entry No.";
        GenJnlLine.Modify();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Exp. User Feedback Gen. Jnl.", DataExch);

        // Verify
        GenJnlLine.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", GenJnlLine."Line No.");
        GenJnlLine.TestField("Exported to Payment File", true);
        VendorLedgerEntry.Get(GenJnlLine."Source Line No.");
        VendorLedgerEntry.TestField("Exported to Payment File", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReExportFromOlderVersion()
    var
        CreditTransferRegister: Record "Credit Transfer Register";
    begin
        // create CrTransf without file in blob
        CreateDummyCreditTransferRegister(CreditTransferRegister, false);

        // re-export
        asserterror
          CreditTransferRegister.Reexport;

        Assert.ExpectedError('The original payment file was not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ViewReExportHistory()
    var
        CreditTransferRegister: Record "Credit Transfer Register";
        CreditTransferRegistersPage: TestPage "Credit Transfer Registers";
        CreditTransReexportHistoryPage: TestPage "Credit Trans Re-export History";
    begin
        // create CrTransf with file in blob
        CreateDummyCreditTransferRegister(CreditTransferRegister, true);

        CreditTransferRegistersPage.OpenView;
        CreditTransferRegistersPage.GotoRecord(CreditTransferRegister);

        // AC:
        CreditTransReexportHistoryPage.Trap;
        CreditTransferRegistersPage.ReexportHistory.Invoke;

        CreditTransReexportHistoryPage.OK.Invoke;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetFiltersOnCreditTransferEntryForVendorLedgerEntryAppliesToID()
    var
        CreditTransferEntry: Record "Credit Transfer Entry";
        CreditTransferEntryFiltered: Record "Credit Transfer Entry";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlShowCTEntries: Codeunit "Gen. Jnl.-Show CT Entries";
    begin
        // [SCENARIO 344738] GenJnlShowCTEntries sets corect filters on CreditTransferEntry for VendorLedgerEntry with "Applies-To ID"
        Initialize();

        // [GIVEN] Gen. Journal Line applied to Vendor Ledger Entry with Applied-to ID
        CreateAndPostPurchaseInvoice(
          GenJnlLine, LibraryPurchase.CreateVendorNo(),
          LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(), LibraryRandom.RandDecInRange(100, 200, 2));
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJnlLine."Document No.");
        VendorLedgerEntry.Validate("Applies-to ID", GenJnlLine."Document No.");
        VendorLedgerEntry.Modify(true);

        // [GIVEN] Created CreditTransferRegister and CreditTransferEntry, applied to the VendorLedgerEntry
        CreateCreditTransferRegisterEntryApplied(
          CreditTransferEntry, GenJnlBatch, GenJnlLine, VendorLedgerEntry."Entry No.", GenJnlLine.Amount / 2);

        // [WHEN] Run SetFiltersOnCreditTransferEntry procedure from Gen. Jnl.-Show CT Entries codeunit for CreditTransferEntryFiltered
        GenJnlShowCTEntries.SetFiltersOnCreditTransferEntry(GenJnlLine, CreditTransferEntryFiltered);

        // [THEN] Filters on CreditTransferEntryFiltered point to the according CreditTransferEntry
        CreditTransferEntryFiltered.FindFirst();
        CreditTransferEntry.TestField("Credit Transfer Register No.", CreditTransferEntryFiltered."Credit Transfer Register No.");
        CreditTransferEntry.TestField("Entry No.", CreditTransferEntryFiltered."Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetFiltersOnCreditTransferEntryForCustomerLedgerEntryAppliesToID()
    var
        CreditTransferEntry: Record "Credit Transfer Entry";
        CreditTransferEntryFiltered: Record "Credit Transfer Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlShowCTEntries: Codeunit "Gen. Jnl.-Show CT Entries";
    begin
        // [SCENARIO 344738] GenJnlShowCTEntries sets corect filters on CreditTransferEntry for CustomerLedgerEntry with "Applies-To ID"
        Initialize();

        // [GIVEN] Gen. Journal Line applied to Customer Ledger Entry with Applied-to ID
        CreateAndPostSalesInvoice(
          GenJnlLine, LibrarySales.CreateCustomerNo,
          LibraryUtility.GenerateGUID(), '', LibraryRandom.RandDecInRange(100, 200, 2));
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJnlLine."Document No.");
        CustLedgerEntry.Validate("Applies-to ID", GenJnlLine."Document No.");
        CustLedgerEntry.Modify(true);

        // [GIVEN] Created CreditTransferRegister and CreditTransferEntry, applied to the CustomerLedgerEntry
        CreateCreditTransferRegisterEntryApplied(
          CreditTransferEntry, GenJnlBatch, GenJnlLine, CustLedgerEntry."Entry No.", GenJnlLine.Amount / 2);

        // [WHEN] Run SetFiltersOnCreditTransferEntry procedure from Gen. Jnl.-Show CT Entries codeunit for CreditTransferEntryFiltered
        GenJnlShowCTEntries.SetFiltersOnCreditTransferEntry(GenJnlLine, CreditTransferEntryFiltered);

        // [THEN] Filters on CreditTransferEntryFiltered point to the according CreditTransferEntry
        CreditTransferEntryFiltered.FindFirst();
        CreditTransferEntry.TestField("Credit Transfer Register No.", CreditTransferEntryFiltered."Credit Transfer Register No.");
        CreditTransferEntry.TestField("Entry No.", CreditTransferEntryFiltered."Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetFiltersOnCreditTransferEntryForEmployeeLedgerEntryAppliesToID()
    var
        BankAcc: Record "Bank Account";
        CreditTransferEntry: Record "Credit Transfer Entry";
        CreditTransferEntryFiltered: Record "Credit Transfer Entry";
        Employee: Record Employee;
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlShowCTEntries: Codeunit "Gen. Jnl.-Show CT Entries";
    begin
        // [SCENARIO 344738] GenJnlShowCTEntries sets corect filters on CreditTransferEntry for EmployeeLedgerEntry with "Applies-To ID"
        Initialize;

        // [GIVEN] Gen. Journal Line applied to Employee Ledger Entry with Applied-to ID
        PreSetupForEmployee(BankAcc, Employee, GenJnlLine);
        GenJnlLine.Validate("Applies-to ID", GenJnlLine."Document No.");
        GenJnlLine.Modify(true);
        EmployeeLedgerEntry.SetRange("Employee No.", Employee."No.");
        EmployeeLedgerEntry.FindLast();
        EmployeeLedgerEntry.Validate("Applies-to ID", GenJnlLine."Document No.");
        EmployeeLedgerEntry.Modify(true);

        // [GIVEN] Created CreditTransferRegister and CreditTransferEntry, applied to the EmployeeLedgerEntry
        CreateCreditTransferRegisterEntryApplied(
          CreditTransferEntry, GenJnlBatch, GenJnlLine, EmployeeLedgerEntry."Entry No.", GenJnlLine.Amount / 2);

        // [WHEN] Run SetFiltersOnCreditTransferEntry procedure from Gen. Jnl.-Show CT Entries codeunit for CreditTransferEntryFiltered
        GenJnlShowCTEntries.SetFiltersOnCreditTransferEntry(GenJnlLine, CreditTransferEntryFiltered);

        // [THEN] Filters on CreditTransferEntryFiltered point to the according CreditTransferEntry
        CreditTransferEntryFiltered.FindFirst();
        CreditTransferEntry.TestField("Credit Transfer Register No.", CreditTransferEntryFiltered."Credit Transfer Register No.");
        CreditTransferEntry.TestField("Entry No.", CreditTransferEntryFiltered."Entry No.");
    end;

    local procedure CreateCreditTransferRegisterEntryApplied(var CreditTransferEntry: Record "Credit Transfer Entry"; GenJnlBatch: Record "Gen. Journal Batch"; GenJnlLine: Record "Gen. Journal Line"; LedgerEntryNo: Integer; TransferAmount: Decimal)
    var
        CreditTransferRegister: Record "Credit Transfer Register";
    begin
        CreditTransferRegister.CreateNew(LibraryUtility.GenerateGUID, GenJnlBatch."Bal. Account No.");
        CreditTransferRegister.FindLast();
        CreditTransferEntry.CreateNew(CreditTransferRegister."No.", 1,
          GenJnlLine."Account Type", GenJnlLine."Account No.", LedgerEntryNo,
          GenJnlLine."Posting Date", GenJnlLine."Currency Code", TransferAmount, '',
          GenJnlLine."Recipient Bank Account", GenJnlLine."Message to Recipient");
        CreditTransferRegister.Validate(Status, CreditTransferRegister.Status::"File Created");
        CreditTransferRegister.Modify(true);
    end;

    local procedure CreateAndPostSalesInvoice(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; DocNo: Code[20]; ExtDocNo: Code[20]; Amount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);

        GenJournalLine.Validate("Document No.", DocNo);
        GenJournalLine.Validate("External Document No.", ExtDocNo);
        GenJournalLine.Validate("Applies-to ID", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPurchaseInvoice(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; DocNo: Code[20]; ExtDocNo: Code[20]; Amount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, VendorNo, -Amount);

        GenJournalLine.Validate("Document No.", DocNo);
        GenJournalLine.Validate("External Document No.", ExtDocNo);
        GenJournalLine.Validate("Applies-to ID", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateExportGenJournalBatch(var GenJnlBatch: Record "Gen. Journal Batch"; BalAccountNo: Code[20])
    begin
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, LibraryPaymentExport.SelectPaymentJournalTemplate);
        GenJnlBatch.Validate("Bal. Account Type", GenJnlBatch."Bal. Account Type"::"Bank Account");
        GenJnlBatch.Validate("Bal. Account No.", BalAccountNo);
        GenJnlBatch.Validate("Allow Payment Export", true);
        GenJnlBatch.Modify(true);
    end;

    local procedure CreateVendorBankAccount(var VendorBankAcc: Record "Vendor Bank Account"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAcc, VendorNo);
        VendorBankAcc.IBAN := LibraryUtility.GenerateGUID;
        VendorBankAcc."SWIFT Code" := LibraryUtility.GenerateGUID;
        VendorBankAcc.Modify();
    end;

    local procedure CreateCustomerBankAccount(var CustomerBankAccount: Record "Customer Bank Account"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CustomerNo);
        CustomerBankAccount.IBAN := LibraryUtility.GenerateGUID;
        CustomerBankAccount."SWIFT Code" := LibraryUtility.GenerateGUID;
        CustomerBankAccount.Modify();
    end;

    local procedure CreateDummyCreditTransferRegister(var CreditTransferRegister: Record "Credit Transfer Register"; AddFileToBlob: Boolean)
    var
        Stream: OutStream;
    begin
        if CreditTransferRegister.FindLast then;
        CreditTransferRegister."No." += 1;
        CreditTransferRegister.Insert();

        if not AddFileToBlob then
            exit;

        CreditTransferRegister."Exported File".CreateOutStream(Stream);
        Stream.WriteText('File content.');
        CreditTransferRegister.Modify();
    end;

    local procedure CreateBalanceSheetAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate(Blocked, false);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Credit Transfer Register UT");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Credit Transfer Register UT");
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup;
        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdateGeneralPostingSetup;

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Credit Transfer Register UT");
    end;

    local procedure PreSetup(var BankAcc: Record "Bank Account"; var Vendor: Record Vendor; var VendorBankAccount: Record "Vendor Bank Account"; var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvoiceNo: Code[20];
    begin
        LibraryERM.CreateBankAccount(BankAcc);
        CreateExportGenJournalBatch(GenJnlBatch, BankAcc."No.");

        LibraryPurchase.CreateVendor(Vendor);
        CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine."Direct Unit Cost" := LibraryRandom.RandDec(1000, 2);
        PurchaseLine.Modify();
        PurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        VendorLedgerEntry.FindLast;

        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", PurchaseLine."Direct Unit Cost");
        GenJnlLine."Recipient Bank Account" := VendorBankAccount.Code;
        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice;
        GenJnlLine."Applies-to Doc. No." := PurchInvoiceNo;
        GenJnlLine."Source Line No." := VendorLedgerEntry."Entry No.";
        GenJnlLine.Modify();
    end;

    local procedure PreSetupForEmployee(var BankAcc: Record "Bank Account"; var Employee: Record Employee; var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        LibraryERM.CreateBankAccount(BankAcc);
        CreateExportGenJournalBatch(GenJnlBatch, BankAcc."No.");

        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);

        Amount := LibraryRandom.RandDecInRange(1, 100, 2);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::" ",
          GenJnlLine."Account Type"::"G/L Account", CreateBalanceSheetAccount,
          GenJnlLine."Bal. Account Type"::Employee, Employee."No.", Amount);
        DocumentNo := GenJnlLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        EmployeeLedgerEntry.FindLast;

        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::" ",
          GenJnlLine."Account Type"::Employee, Employee."No.", Amount);
        GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::" ";
        GenJnlLine."Applies-to Doc. No." := DocumentNo;
        GenJnlLine."Source Line No." := EmployeeLedgerEntry."Entry No.";
        GenJnlLine.Modify();
    end;
}

