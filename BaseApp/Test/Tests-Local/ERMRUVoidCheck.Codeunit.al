codeunit 144015 "ERM RU Void Check"
{
    // // [FEATURE] [Void Check]
    // TEST FUNCTION NAME                           TFS ID
    // UnapplyAndVoidMultiplePurchApplication        91336
    // UnapplyAndVoidMultipleSalesApplication        91336

    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryJournals: Codeunit "Library - Journals";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        ExpectedCorrectionEntriesErr: Label 'Correction G/L Entries are expected (Debit, Credit Amount <= 0)';
        ExpectedNotCorrectionEntriesErr: Label 'Not correction G/L Entries are expected (Debit, Credit Amount >= 0)';
        VoidType: Option "Unapply and void check","Void check only";
        BankPaymentType: Option " ","Computer Check","Manual Check";
        FieldIsNotEditableErr: Label 'Field %1 is no editable';

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure PurchaseMultipleApplication_CashOutgoing_ManualCheck_UnapplyAndVoid()
    begin
        // [FEATURE] [Purchase] [Manual Check] [Unapply]
        // [SCENARIO 377546] Unapply And Void Check for vendor payment applied to several invoices in case of "Void Payment as Correction" = FALSE

        // [GIVEN] Three vendor invoices "I1", "I2", "I3"
        // [GIVEN] Payment "P" with "Manual Check", applied to invoices "I1", "I2", "I3"
        // [WHEN] Unapply And Void Check for payment "P" using GeneralLedgerSetup."Void Payment as Correction" = FALSE
        PurchaseMultipleApplication_CashOutgoing_Scenario(BankPaymentType::"Manual Check", VoidType::"Unapply and void check", false);

        // [THEN] Vendor invoice ledger entries are Open
        // [THEN] Last G/L Register doesn't have Correction Entries (Debit, Credit amounts >= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsNotCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure PurchaseMultipleApplication_CashOutgoing_ManualCheck_UnapplyAndVoid_AsCorrection()
    begin
        // [FEATURE] [Purchase] [Manual Check] [Unapply] [Correction]
        // [SCENARIO 377546] Unapply And Void Check for vendor payment applied to several invoices in case of "Void Payment as Correction" = TRUE

        // [GIVEN] Three vendor invoices "I1", "I2", "I3"
        // [GIVEN] Payment "P" with "Manual Check", applied to invoices "I1", "I2", "I3"
        // [WHEN] Unapply And Void Check for payment "P" using GeneralLedgerSetup."Void Payment as Correction" = TRUE
        PurchaseMultipleApplication_CashOutgoing_Scenario(BankPaymentType::"Manual Check", VoidType::"Unapply and void check", true);

        // [THEN] Vendor invoice ledger entries are Open
        // [THEN] Last G/L Register has Correction Entries (Debit, Credit amounts <= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure PurchaseMultipleApplication_CashOutgoing_ManualCheck_VoidOnly()
    begin
        // [FEATURE] [Purchase] [Manual Check]
        // [SCENARIO 377546] Void Check Only for vendor payment applied to several invoices in case of "Void Payment as Correction" = FALSE

        // [GIVEN] Three vendor invoices "I1", "I2", "I3"
        // [GIVEN] Payment "P" with "Manual Check", applied to invoices "I1", "I2", "I3"
        // [WHEN] Void Check Only for payment "P" using GeneralLedgerSetup."Void Payment as Correction" = FALSE
        PurchaseMultipleApplication_CashOutgoing_Scenario(BankPaymentType::"Manual Check", VoidType::"Void check only", false);

        // [THEN] Vendor invoice ledger entries are Closed
        // [THEN] Last G/L Register doesn't have Correction Entries (Debit, Credit amounts >= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsNotCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure PurchaseMultipleApplication_CashOutgoing_ManualCheck_VoidOnly_AsCorrection()
    begin
        // [FEATURE] [Purchase] [Manual Check] [Correction]
        // [SCENARIO 377546] Void Check Only for vendor payment applied to several invoices in case of "Void Payment as Correction" = TRUE

        // [GIVEN] Three vendor invoices "I1", "I2", "I3"
        // [GIVEN] Payment "P" with "Manual Check", applied to invoices "I1", "I2", "I3"
        // [WHEN] Void Check Only for payment "P" using GeneralLedgerSetup."Void Payment as Correction" = TRUE
        PurchaseMultipleApplication_CashOutgoing_Scenario(BankPaymentType::"Manual Check", VoidType::"Void check only", true);

        // [THEN] Vendor invoice ledger entries are Closed
        // [THEN] Last G/L Register has Correction Entries (Debit, Credit amounts <= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure PurchaseMultipleApplication_CashOutgoing_ComputerCheck_UnapplyAndVoid()
    begin
        // [FEATURE] [Purchase] [Computer Check] [Unapply]
        // [SCENARIO 377546] Unapply And Void Check for vendor payment applied to several invoices in case of "Void Payment as Correction" = FALSE

        // [GIVEN] Three vendor invoices "I1", "I2", "I3"
        // [GIVEN] Payment "P" with "Computer Check", applied to invoices "I1", "I2", "I3"
        // [WHEN] Unapply And Void Check for payment "P" using GeneralLedgerSetup."Void Payment as Correction" = FALSE
        PurchaseMultipleApplication_CashOutgoing_Scenario(BankPaymentType::"Computer Check", VoidType::"Unapply and void check", false);

        // [THEN] Vendor invoice ledger entries are Open
        // [THEN] Last G/L Register doesn't have Correction Entries (Debit, Credit amounts >= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsNotCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure PurchaseMultipleApplication_CashOutgoing_ComputerCheck_UnapplyAndVoid_AsCorrection()
    begin
        // [FEATURE] [Purchase] [Computer Check] [Unapply] [Correction]
        // [SCENARIO 377546] Unapply And Void Check for vendor payment applied to several invoices in case of "Void Payment as Correction" = TRUE

        // [GIVEN] Three vendor invoices "I1", "I2", "I3"
        // [GIVEN] Payment "P" with "Computer Check", applied to invoices "I1", "I2", "I3"
        // [WHEN] Unapply And Void Check for payment "P" using GeneralLedgerSetup."Void Payment as Correction" = TRUE
        PurchaseMultipleApplication_CashOutgoing_Scenario(BankPaymentType::"Computer Check", VoidType::"Unapply and void check", true);

        // [THEN] Vendor invoice ledger entries are Open
        // [THEN] Last G/L Register has Correction Entries (Debit, Credit amounts <= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure PurchaseMultipleApplication_CashOutgoing_ComputerCheck_VoidOnly()
    begin
        // [FEATURE] [Purchase] [Computer Check]
        // [SCENARIO 377546] Void Check Only for vendor payment applied to several invoices in case of "Void Payment as Correction" = FALSE

        // [GIVEN] Three vendor invoices "I1", "I2", "I3"
        // [GIVEN] Payment "P" with "Computer Check", applied to invoices "I1", "I2", "I3"
        // [WHEN] Void Check Only for payment "P" using GeneralLedgerSetup."Void Payment as Correction" = FALSE
        PurchaseMultipleApplication_CashOutgoing_Scenario(BankPaymentType::"Computer Check", VoidType::"Void check only", false);

        // [THEN] Vendor invoice ledger entries are Closed
        // [THEN] Last G/L Register doesn't have Correction Entries (Debit, Credit amounts >= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsNotCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure PurchaseMultipleApplication_CashOutgoing_ComputerCheck_VoidOnly_AsCorrection()
    begin
        // [FEATURE] [Purchase] [Computer Check] [Correction]
        // [SCENARIO 377546] Void Check Only for vendor payment applied to several invoices in case of "Void Payment as Correction" = TRUE

        // [GIVEN] Three vendor invoices "I1", "I2", "I3"
        // [GIVEN] Payment "P" with "Computer Check", applied to invoices "I1", "I2", "I3"
        // [WHEN] Void Check Only for payment "P" using GeneralLedgerSetup."Void Payment as Correction" = TRUE
        PurchaseMultipleApplication_CashOutgoing_Scenario(BankPaymentType::"Computer Check", VoidType::"Void check only", true);

        // [THEN] Vendor invoice ledger entries are Closed
        // [THEN] Last G/L Register has Correction Entries (Debit, Credit amounts <= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure PurchaseMultipleApplication_CashIngoing_ComputerCheck_UnapplyAndVoid()
    begin
        // [FEATURE] [Purchase] [Computer Check] [Unapply]
        // [SCENARIO 377546] Unapply And Void Check for vendor refund applied to several payments in case of "Void Payment as Correction" = FALSE

        // [GIVEN] Three vendor payments "P1", "P2", "P3"
        // [GIVEN] Vendor refund "R" with "Computer Check", applied to payments "P1", "P2", "P3"
        // [WHEN] Unapply And Void Check for refund "R" using GeneralLedgerSetup."Void Payment as Correction" = FALSE
        PurchaseMultipleApplication_CashIngoing_Scenario(BankPaymentType::"Computer Check", VoidType::"Unapply and void check", false);

        // [THEN] Vendor payment ledger entries are Open
        // [THEN] Last G/L Register doesn't have Correction Entries (Debit, Credit amounts >= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsNotCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure PurchaseMultipleApplication_CashIngoing_ComputerCheck_UnapplyAndVoid_AsCorrection()
    begin
        // [FEATURE] [Purchase] [Computer Check] [Unapply] [Correction]
        // [SCENARIO 377546] Unapply And Void Check for vendor refund applied to several payments in case of "Void Payment as Correction" = TRUE

        // [GIVEN] Three vendor payments "P1", "P2", "P3"
        // [GIVEN] Vendor refund "R" with "Computer Check", applied to payments "P1", "P2", "P3"
        // [WHEN] Unapply And Void Check for refund "R" using GeneralLedgerSetup."Void Payment as Correction" = TRUE
        PurchaseMultipleApplication_CashIngoing_Scenario(BankPaymentType::"Computer Check", VoidType::"Unapply and void check", true);

        // [THEN] Vendor payment ledger entries are Open
        // [THEN] Last G/L Register has Correction Entries (Debit, Credit amounts <= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure PurchaseMultipleApplication_CashIngoing_ComputerCheck_VoidOnly()
    begin
        // [FEATURE] [Purchase] [Computer Check]
        // [SCENARIO 377546] Void Check Only for vendor refund applied to several payments in case of "Void Payment as Correction" = FALSE

        // [GIVEN] Three vendor payments "P1", "P2", "P3"
        // [GIVEN] Vendor refund "R" with "Computer Check", applied to payments "P1", "P2", "P3"
        // [WHEN] Void Check Only for refund "R" using GeneralLedgerSetup."Void Payment as Correction" = FALSE
        PurchaseMultipleApplication_CashIngoing_Scenario(BankPaymentType::"Computer Check", VoidType::"Void check only", false);

        // [THEN] Vendor payment ledger entries are Closed
        // [THEN] Last G/L Register doesn't have Correction Entries (Debit, Credit amounts >= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsNotCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure PurchaseMultipleApplication_CashIngoing_ComputerCheck_VoidOnly_AsCorrection()
    begin
        // [FEATURE] [Purchase] [Computer Check] [Correction]
        // [SCENARIO 377546] Void Check Only for vendor refund applied to several payments in case of "Void Payment as Correction" = TRUE

        // [GIVEN] Three vendor payments "P1", "P2", "P3"
        // [GIVEN] Vendor refund "R" with "Computer Check", applied to payments "P1", "P2", "P3"
        // [WHEN] Void Check Only for refund "R" using GeneralLedgerSetup."Void Payment as Correction" = TRUE
        PurchaseMultipleApplication_CashIngoing_Scenario(BankPaymentType::"Computer Check", VoidType::"Void check only", true);

        // [THEN] Vendor payment ledger entries are Closed
        // [THEN] Last G/L Register has Correction Entries (Debit, Credit amounts <= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure SalesMultipleApplication_CashOutgoing_ManualCheck_UnapplyAndVoid()
    begin
        // [FEATURE] [Sales] [Manual Check] [Unapply]
        // [SCENARIO 377546] Unapply And Void Check for customer refund applied to several payments in case of "Void Payment as Correction" = FALSE

        // [GIVEN] Three customer payments "P1", "P2", "P3"
        // [GIVEN] Customer refund "R" with "Manual Check", applied to payments "P1", "P2", "P3"
        // [WHEN] Unapply And Void Check for refund "R" using GeneralLedgerSetup."Void Payment as Correction" = FALSE
        SalesMultipleApplication_CashOutgoing_Scenario(BankPaymentType::"Manual Check", VoidType::"Unapply and void check", false);

        // [THEN] Customer payment ledger entries are Open
        // [THEN] Last G/L Register doesn't have Correction Entries (Debit, Credit amounts >= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsNotCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure SalesMultipleApplication_CashOutgoing_ManualCheck_UnapplyAndVoid_AsCorrection()
    begin
        // [FEATURE] [Sales] [Manual Check] [Unapply] [Correction]
        // [SCENARIO 377546] Unapply And Void Check for customer refund applied to several payments in case of "Void Payment as Correction" = TRUE

        // [GIVEN] Three customer payments "P1", "P2", "P3"
        // [GIVEN] Customer refund "R" with "Manual Check", applied to payments "P1", "P2", "P3"
        // [WHEN] Unapply And Void Check for refund "R" using GeneralLedgerSetup."Void Payment as Correction" = TRUE
        SalesMultipleApplication_CashOutgoing_Scenario(BankPaymentType::"Manual Check", VoidType::"Unapply and void check", true);

        // [THEN] Customer payment ledger entries are Open
        // [THEN] Last G/L Register has Correction Entries (Debit, Credit amounts <= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure SalesMultipleApplication_CashOutgoing_ManualCheck_VoidOnly()
    begin
        // [FEATURE] [Sales] [Manual Check]
        // [SCENARIO 377546] Void Check Only for customer refund applied to several payments in case of "Void Payment as Correction" = FALSE

        // [GIVEN] Three customer payments "P1", "P2", "P3"
        // [GIVEN] Customer refund "R" with "Manual Check", applied to payments "P1", "P2", "P3"
        // [WHEN] Void Check Only for refund "R" using GeneralLedgerSetup."Void Payment as Correction" = FALSE
        SalesMultipleApplication_CashOutgoing_Scenario(BankPaymentType::"Manual Check", VoidType::"Void check only", false);

        // [THEN] Customer payment ledger entries are Closed
        // [THEN] Last G/L Register doesn't have Correction Entries (Debit, Credit amounts >= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsNotCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure SalesMultipleApplication_CashOutgoing_ManualCheck_VoidOnly_AsCorrection()
    begin
        // [FEATURE] [Sales] [Manual Check] [Correction]
        // [SCENARIO 377546] Void Check Only for customer refund applied to several payments in case of "Void Payment as Correction" = TRUE

        // [GIVEN] Three customer payments "P1", "P2", "P3"
        // [GIVEN] Customer refund "R" with "Manual Check", applied to payments "P1", "P2", "P3"
        // [WHEN] Void Check Only for refund "R" using GeneralLedgerSetup."Void Payment as Correction" = TRUE
        SalesMultipleApplication_CashOutgoing_Scenario(BankPaymentType::"Manual Check", VoidType::"Void check only", true);

        // [THEN] Customer payment ledger entries are Closed
        // [THEN] Last G/L Register has Correction Entries (Debit, Credit amounts <= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure SalesMultipleApplication_CashOutgoing_ComputerCheck_UnapplyAndVoid()
    begin
        // [FEATURE] [Sales] [Computer Check] [Unapply]
        // [SCENARIO 377546] Unapply And Void Check for customer refund applied to several payments in case of "Void Payment as Correction" = FALSE

        // [GIVEN] Three customer payments "P1", "P2", "P3"
        // [GIVEN] Customer refund "R" with "Computer Check", applied to payments "P1", "P2", "P3"
        // [WHEN] Unapply And Void Check for refund "R" using GeneralLedgerSetup."Void Payment as Correction" = FALSE
        SalesMultipleApplication_CashOutgoing_Scenario(BankPaymentType::"Computer Check", VoidType::"Unapply and void check", false);

        // [THEN] Customer payment ledger entries are Open
        // [THEN] Last G/L Register doesn't have Correction Entries (Debit, Credit amounts >= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsNotCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure SalesMultipleApplication_CashOutgoing_ComputerCheck_UnapplyAndVoid_AsCorrection()
    begin
        // [FEATURE] [Sales] [Computer Check] [Unapply] [Correction]
        // [SCENARIO 377546] Unapply And Void Check for customer refund applied to several payments in case of "Void Payment as Correction" = TRUE

        // [GIVEN] Three customer payments "P1", "P2", "P3"
        // [GIVEN] Customer refund "R" with "Computer Check", applied to payments "P1", "P2", "P3"
        // [WHEN] Unapply And Void Check for refund "R" using GeneralLedgerSetup."Void Payment as Correction" = TRUE
        SalesMultipleApplication_CashOutgoing_Scenario(BankPaymentType::"Computer Check", VoidType::"Unapply and void check", true);

        // [THEN] Customer payment ledger entries are Open
        // [THEN] Last G/L Register has Correction Entries (Debit, Credit amounts <= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure SalesMultipleApplication_CashOutgoing_ComputerCheck_VoidOnly()
    begin
        // [FEATURE] [Sales] [Computer Check]
        // [SCENARIO 377546] Void Check Only for customer refund applied to several payments in case of "Void Payment as Correction" = FALSE

        // [GIVEN] Three customer payments "P1", "P2", "P3"
        // [GIVEN] Customer refund "R" with "Computer Check", applied to payments "P1", "P2", "P3"
        // [WHEN] Void Check Only for refund "R" using GeneralLedgerSetup."Void Payment as Correction" = FALSE
        SalesMultipleApplication_CashOutgoing_Scenario(BankPaymentType::"Computer Check", VoidType::"Void check only", false);

        // [THEN] Customer payment ledger entries are Closed
        // [THEN] Last G/L Register doesn't have Correction Entries (Debit, Credit amounts >= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsNotCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure SalesMultipleApplication_CashOutgoing_ComputerCheck_VoidOnly_AsCorrection()
    begin
        // [FEATURE] [Sales] [Computer Check] [Correction]
        // [SCENARIO 377546] Void Check Only for customer refund applied to several payments in case of "Void Payment as Correction" = TRUE

        // [GIVEN] Three customer payments "P1", "P2", "P3"
        // [GIVEN] Customer refund "R" with "Computer Check", applied to payments "P1", "P2", "P3"
        // [WHEN] Void Check Only for refund "R" using GeneralLedgerSetup."Void Payment as Correction" = TRUE
        SalesMultipleApplication_CashOutgoing_Scenario(BankPaymentType::"Computer Check", VoidType::"Void check only", true);

        // [THEN] Customer payment ledger entries are Closed
        // [THEN] Last G/L Register has Correction Entries (Debit, Credit amounts <= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure SalesMultipleApplication_CashIngoing_ComputerCheck_UnapplyAndVoid()
    begin
        // [FEATURE] [Sales] [Computer Check] [Unapply]
        // [SCENARIO 377546] Unapply And Void Check for customer payment applied to several invoices in case of "Void Payment as Correction" = FALSE

        // [GIVEN] Three customer invoices "I1", "I2", "I3"
        // [GIVEN] Payment "P" with "Computer Check", applied to invoices "I1", "I2", "I3"
        // [WHEN] Unapply And Void Check for payment "P" using GeneralLedgerSetup."Void Payment as Correction" = FALSE
        SalesMultipleApplication_CashIngoing_Scenario(BankPaymentType::"Computer Check", VoidType::"Unapply and void check", false);

        // [THEN] Customer invoice ledger entries are Open
        // [THEN] Last G/L Register doesn't have Correction Entries (Debit, Credit amounts >= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsNotCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure SalesMultipleApplication_CashIngoing_ComputerCheck_UnapplyAndVoid_AsCorrection()
    begin
        // [FEATURE] [Sales] [Computer Check] [Unapply] [Correction]
        // [SCENARIO 377546] Unapply And Void Check for customer payment applied to several invoices in case of "Void Payment as Correction" = TRUE

        // [GIVEN] Three customer invoices "I1", "I2", "I3"
        // [GIVEN] Payment "P" with "Computer Check", applied to invoices "I1", "I2", "I3"
        // [WHEN] Unapply And Void Check for payment "P" using GeneralLedgerSetup."Void Payment as Correction" = TRUE
        SalesMultipleApplication_CashIngoing_Scenario(BankPaymentType::"Computer Check", VoidType::"Unapply and void check", true);

        // [THEN] Customer invoice ledger entries are Open
        // [THEN] Last G/L Register has Correction Entries (Debit, Credit amounts <= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure SalesMultipleApplication_CashIngoing_ComputerCheck_VoidOnly()
    begin
        // [FEATURE] [Sales] [Computer Check]
        // [SCENARIO 377546] Void Check Only for customer payment applied to several invoices in case of "Void Payment as Correction" = FALSE

        // [GIVEN] Three customer invoices "I1", "I2", "I3"
        // [GIVEN] Payment "P" with "Computer Check", applied to invoices "I1", "I2", "I3"
        // [WHEN] Void Check Only for payment "P" using GeneralLedgerSetup."Void Payment as Correction" = FALSE
        SalesMultipleApplication_CashIngoing_Scenario(BankPaymentType::"Computer Check", VoidType::"Void check only", false);

        // [THEN] Customer invoice ledger entries are Closed
        // [THEN] Last G/L Register doesn't have Correction Entries (Debit, Credit amounts >= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsNotCorrectionEntry;
    end;

    [Test]
    [HandlerFunctions('ConfirmVoidCheckMPH')]
    [Scope('OnPrem')]
    procedure SalesMultipleApplication_CashIngoing_ComputerCheck_VoidOnly_AsCorrection()
    begin
        // [FEATURE] [Sales] [Computer Check] [Correction]
        // [SCENARIO 377546] Void Check Only for customer payment applied to several invoices in case of "Void Payment as Correction" = TRUE

        // [GIVEN] Three customer invoices "I1", "I2", "I3"
        // [GIVEN] Payment "P" with "Computer Check", applied to invoices "I1", "I2", "I3"
        // [WHEN] Void Check Only for payment "P" using GeneralLedgerSetup."Void Payment as Correction" = TRUE
        SalesMultipleApplication_CashIngoing_Scenario(BankPaymentType::"Computer Check", VoidType::"Void check only", true);

        // [THEN] Customer invoice ledger entries are Closed
        // [THEN] Last G/L Register has Correction Entries (Debit, Credit amounts <= 0)
        // [THEN] Check Ledger Entry has "Entry Status" = "Financially Voided", "Original Entry Status" = Posted, "Statement Status" = Closed
        VerifyLastRegisterIsCorrectionEntry;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_VoidPaymentAsCorrectionOnGeneralLedgerSetup()
    var
        GenLedgSetup: Record "General Ledger Setup";
        GeneralLedgerSetup: TestPage "General Ledger Setup";
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 378021] Ffield "Void Payment as Correction" should be editable on "General Ledger Setup" page

        Initialize;
        // [WHEN] Open "General Ledger Setup" page
        GeneralLedgerSetup.OpenEdit;

        // [THEN] Field "Void Payment as Correction" is editable on "General Ledger Setup" page
        Assert.IsTrue(
          GeneralLedgerSetup."Void Payment as Correction".Editable,
          StrSubstNo(FieldIsNotEditableErr, GenLedgSetup.FieldCaption("Void Payment as Correction")));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore;
        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        isInitialized := true;
        Commit;
    end;

    local procedure PurchaseMultipleApplication_CashOutgoing_Scenario(BankPaymentTypeLoc: Option; VoidTypeLoc: Option; VoidPaymentAsCorrection: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
        CheckLedgerEntry: Record "Check Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CashAccountNo: Code[20];
        VendNo: Code[20];
        InvNo: array[3] of Code[20];
        PmtNo: Code[20];
        TotalInvAmount: Decimal;
        i: Integer;
    begin
        Initialize;
        SetupVoidPaymentAsCorrection(VoidPaymentAsCorrection);
        CashAccountNo := CreateCashAccount;
        VendNo := LibraryPurchase.CreateVendorNo;

        for i := 1 to ArrayLen(InvNo) do
            InvNo[i] := CreatePostInvoice(TotalInvAmount, GenJnlLine."Account Type"::Vendor, VendNo, -1);
        PmtNo :=
          CreatePostPaymentAppliedToInvoice(
            GenJnlLine."Account Type"::Vendor, VendNo, CashAccountNo, BankPaymentTypeLoc, InvNo[1], TotalInvAmount);

        for i := 2 to ArrayLen(InvNo) do
            ApplyVendorPaymentToInvoice(VendNo, PmtNo, InvNo[i]);

        FindCheckLedgEntry(CheckLedgerEntry, CashAccountNo, CheckLedgerEntry."Document Type"::Payment, PmtNo);
        VoidCheckLedgEntry(CheckLedgerEntry, VoidTypeLoc);

        VerifyVendorLedgerEntries(
          VendNo, VendorLedgerEntry."Document Type"::Invoice, ArrayLen(InvNo), VoidTypeLoc = VoidType::"Unapply and void check");
        VerifyCheckLedgerEntry(
          CheckLedgerEntry,
          CheckLedgerEntry."Entry Status"::"Financially Voided",
          CheckLedgerEntry."Original Entry Status"::Posted,
          CheckLedgerEntry."Statement Status"::Closed);
    end;

    local procedure PurchaseMultipleApplication_CashIngoing_Scenario(BankPaymentTypeLoc: Option; VoidTypeLoc: Option; VoidPaymentAsCorrection: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
        CheckLedgerEntry: Record "Check Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CashAccountNo: Code[20];
        VendNo: Code[20];
        PmtNo: array[3] of Code[20];
        RefundNo: Code[20];
        TotalPmtAmount: Decimal;
        i: Integer;
    begin
        Initialize;
        SetupVoidPaymentAsCorrection(VoidPaymentAsCorrection);
        CashAccountNo := CreateCashAccount;
        VendNo := LibraryPurchase.CreateVendorNo;

        for i := 1 to ArrayLen(PmtNo) do
            TotalPmtAmount += CreatePostPayment(PmtNo[i], GenJnlLine."Account Type"::Vendor, VendNo, 1);
        RefundNo :=
          CreatePostRefundAppliedToPayment(
            GenJnlLine."Account Type"::Vendor, VendNo, CashAccountNo, BankPaymentTypeLoc, PmtNo[1], -TotalPmtAmount);
        for i := 2 to ArrayLen(PmtNo) do
            ApplyVendorRefundToPayment(VendNo, RefundNo, PmtNo[i]);

        FindCheckLedgEntry(CheckLedgerEntry, CashAccountNo, CheckLedgerEntry."Document Type"::Refund, RefundNo);
        VoidCheckLedgEntry(CheckLedgerEntry, VoidTypeLoc);

        VerifyVendorLedgerEntries(
          VendNo, VendorLedgerEntry."Document Type"::Payment, ArrayLen(PmtNo), VoidTypeLoc = VoidType::"Unapply and void check");
        VerifyCheckLedgerEntry(
          CheckLedgerEntry,
          CheckLedgerEntry."Entry Status"::"Financially Voided",
          CheckLedgerEntry."Original Entry Status"::Posted,
          CheckLedgerEntry."Statement Status"::Closed);
    end;

    local procedure SalesMultipleApplication_CashOutgoing_Scenario(BankPaymentTypeLoc: Option; VoidTypeLoc: Option; VoidPaymentAsCorrection: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
        CheckLedgerEntry: Record "Check Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CashAccountNo: Code[20];
        CustNo: Code[20];
        PmtNo: array[3] of Code[20];
        RefundNo: Code[20];
        TotalPmtAmount: Decimal;
        i: Integer;
    begin
        Initialize;
        SetupVoidPaymentAsCorrection(VoidPaymentAsCorrection);
        CashAccountNo := CreateCashAccount;
        CustNo := LibrarySales.CreateCustomerNo;

        for i := 1 to ArrayLen(PmtNo) do
            TotalPmtAmount += CreatePostPayment(PmtNo[i], GenJnlLine."Account Type"::Customer, CustNo, -1);
        RefundNo :=
          CreatePostRefundAppliedToPayment(
            GenJnlLine."Account Type"::Customer, CustNo, CashAccountNo, BankPaymentTypeLoc, PmtNo[1], -TotalPmtAmount);
        for i := 2 to ArrayLen(PmtNo) do
            ApplyCustomerRefundToPayment(CustNo, RefundNo, PmtNo[i]);

        FindCheckLedgEntry(CheckLedgerEntry, CashAccountNo, CheckLedgerEntry."Document Type"::Refund, RefundNo);
        VoidCheckLedgEntry(CheckLedgerEntry, VoidTypeLoc);

        VerifyCustomerLedgerEntries(
          CustNo, CustLedgerEntry."Document Type"::Payment, ArrayLen(PmtNo), VoidTypeLoc = VoidType::"Unapply and void check");
        VerifyCheckLedgerEntry(
          CheckLedgerEntry,
          CheckLedgerEntry."Entry Status"::"Financially Voided",
          CheckLedgerEntry."Original Entry Status"::Posted,
          CheckLedgerEntry."Statement Status"::Closed);
    end;

    local procedure SalesMultipleApplication_CashIngoing_Scenario(BankPaymentTypeLoc: Option; VoidTypeLoc: Option; VoidPaymentAsCorrection: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
        CheckLedgerEntry: Record "Check Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CashAccountNo: Code[20];
        CustNo: Code[20];
        InvNo: array[3] of Code[20];
        PmtNo: Code[20];
        TotalInvAmount: Decimal;
        i: Integer;
    begin
        Initialize;
        SetupVoidPaymentAsCorrection(VoidPaymentAsCorrection);
        CashAccountNo := CreateCashAccount;
        CustNo := LibrarySales.CreateCustomerNo;

        for i := 1 to ArrayLen(InvNo) do
            InvNo[i] := CreatePostInvoice(TotalInvAmount, GenJnlLine."Account Type"::Customer, CustNo, 1);
        PmtNo :=
          CreatePostPaymentAppliedToInvoice(
            GenJnlLine."Account Type"::Customer, CustNo, CashAccountNo, BankPaymentTypeLoc, InvNo[1], -TotalInvAmount);

        for i := 2 to ArrayLen(InvNo) do
            ApplyCustomerPaymentToInvoice(CustNo, PmtNo, InvNo[i]);

        FindCheckLedgEntry(CheckLedgerEntry, CashAccountNo, CheckLedgerEntry."Document Type"::Payment, PmtNo);
        VoidCheckLedgEntry(CheckLedgerEntry, VoidTypeLoc);

        VerifyCustomerLedgerEntries(
          CustNo, CustLedgerEntry."Document Type"::Invoice, ArrayLen(InvNo), VoidTypeLoc = VoidType::"Unapply and void check");
        VerifyCheckLedgerEntry(
          CheckLedgerEntry,
          CheckLedgerEntry."Entry Status"::"Financially Voided",
          CheckLedgerEntry."Original Entry Status"::Posted,
          CheckLedgerEntry."Statement Status"::Closed);
    end;

    local procedure SetupVoidPaymentAsCorrection(NewVoidPaymentAsCorrection: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get;
        GeneralLedgerSetup.Validate("Void Payment as Correction", NewVoidPaymentAsCorrection);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure CreatePostInvoice(var TotalInvAmount: Decimal; AccountType: Option; AccountNo: Code[20]; AmountSign: Integer): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        with GenJournalLine do begin
            CreateGenJournalLine(
              GenJournalLine, "Document Type"::Invoice, AccountType, AccountNo, "Bal. Account Type"::"Bank Account",
              LibraryERM.CreateBankAccountNo, 0, '', "Bank Payment Type"::" ", AmountSign * LibraryRandom.RandDec(100, 2));
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
            TotalInvAmount += Abs(Amount);
            exit("Document No.");
        end;
    end;

    local procedure CreatePostPayment(var DocumentNo: Code[20]; AccountType: Option; AccountNo: Code[20]; AmountSign: Integer): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        with GenJournalLine do begin
            CreateGenJournalLine(
              GenJournalLine, "Document Type"::Payment, AccountType, AccountNo,
              "Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo, 0, '',
              "Bank Payment Type"::" ", AmountSign * LibraryRandom.RandDec(100, 2));
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
            DocumentNo := "Document No.";
            exit(Amount);
        end;
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocType: Option; AccountType: Option; AccountNo: Code[20]; BalAccountType: Option; BalAccountNo: Code[20]; AppliesToDocType: Option; AppliesToDocNo: Code[20]; BankPaymentType: Option; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocType, AccountType, AccountNo, BalAccountType, BalAccountNo, Amount);
        GenJournalLine.Validate("Bank Payment Type", BankPaymentType);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePostPaymentAppliedToInvoice(AccountType: Option; AccountNo: Code[20]; BankAccountNo: Code[20]; BankPaymentTypeLoc: Option; InvNo: Code[20]; AmountToApply: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        with GenJournalLine do begin
            CreateGenJournalLine(
              GenJournalLine, "Document Type"::Payment, AccountType, AccountNo, "Bal. Account Type"::"Bank Account",
              BankAccountNo, "Applies-to Doc. Type"::Invoice, InvNo, BankPaymentTypeLoc, AmountToApply);
            if BankPaymentTypeLoc = BankPaymentType::"Computer Check" then
                PrintCashOrder(GenJournalLine);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
            exit("Document No.");
        end;
    end;

    local procedure CreatePostRefundAppliedToPayment(AccountType: Option; AccountNo: Code[20]; BankAccountNo: Code[20]; BankPaymentTypeLoc: Option; InvNo: Code[20]; AmountToApply: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        with GenJournalLine do begin
            CreateGenJournalLine(
              GenJournalLine, "Document Type"::Refund, AccountType, AccountNo, "Bal. Account Type"::"Bank Account",
              BankAccountNo, "Applies-to Doc. Type"::Payment, InvNo, BankPaymentTypeLoc, AmountToApply);
            if BankPaymentTypeLoc = BankPaymentType::"Computer Check" then
                PrintCashOrder(GenJournalLine);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
            exit("Document No.");
        end;
    end;

    local procedure CreateCashAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        with BankAccount do begin
            Validate("Account Type", "Account Type"::"Cash Account");
            Validate("Debit Cash Order No. Series", LibraryERM.CreateNoSeriesCode);
            Validate("Credit Cash Order No. Series", "Debit Cash Order No. Series");
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure ApplyVendorPaymentToInvoice(VendorNo: Code[20]; PmtNo: Code[20]; InvNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        ApplyVendorLedgerEntry(
          VendorNo,
          VendorLedgerEntry."Document Type"::Payment, PmtNo,
          VendorLedgerEntry."Document Type"::Invoice, InvNo);
    end;

    local procedure ApplyVendorRefundToPayment(VendorNo: Code[20]; RefundNo: Code[20]; PmtNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        ApplyVendorLedgerEntry(
          VendorNo,
          VendorLedgerEntry."Document Type"::Refund, RefundNo,
          VendorLedgerEntry."Document Type"::Payment, PmtNo);
    end;

    local procedure ApplyCustomerPaymentToInvoice(CustomerNo: Code[20]; PaymentNo: Code[20]; InvoiceNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        ApplyCustomerLedgerEntry(
          CustomerNo,
          CustLedgEntry."Document Type"::Payment, PaymentNo,
          CustLedgEntry."Document Type"::Invoice, InvoiceNo);
    end;

    local procedure ApplyCustomerRefundToPayment(CustomerNo: Code[20]; RefundNo: Code[20]; PmtNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        ApplyCustomerLedgerEntry(
          CustomerNo,
          CustLedgEntry."Document Type"::Refund, RefundNo,
          CustLedgEntry."Document Type"::Payment, PmtNo);
    end;

    local procedure ApplyVendorLedgerEntry(VendorNo: Code[20]; ApplyingDocType: Option; ApplyingDocNo: Code[20]; AppliesToDocType: Option; AppliesToDocNo: Code[20])
    var
        ApplyingVendLedgEntry: Record "Vendor Ledger Entry";
        AppliesToVendLedgEntry: Record "Vendor Ledger Entry";
    begin
        ApplyingVendLedgEntry.SetRange("Vendor No.", VendorNo);
        AppliesToVendLedgEntry.SetRange("Vendor No.", VendorNo);
        LibraryERM.FindVendorLedgerEntry(ApplyingVendLedgEntry, ApplyingDocType, ApplyingDocNo);
        ApplyingVendLedgEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(ApplyingVendLedgEntry, ApplyingVendLedgEntry."Remaining Amount");
        LibraryERM.FindVendorLedgerEntry(AppliesToVendLedgEntry, AppliesToDocType, AppliesToDocNo);
        AppliesToVendLedgEntry.SetRange(Open, true);
        LibraryERM.SetAppliestoIdVendor(AppliesToVendLedgEntry);
        LibraryERM.PostVendLedgerApplication(ApplyingVendLedgEntry);
    end;

    local procedure ApplyCustomerLedgerEntry(CustomerNo: Code[20]; ApplyingDocType: Option; ApplyingDocNo: Code[20]; AppliesToDocType: Option; AppliesToDocNo: Code[20])
    var
        ApplyingCustLedgEntry: Record "Cust. Ledger Entry";
        AppliesToCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        ApplyingCustLedgEntry.SetRange("Customer No.", CustomerNo);
        AppliesToCustLedgEntry.SetRange("Customer No.", CustomerNo);
        LibraryERM.FindCustomerLedgerEntry(ApplyingCustLedgEntry, ApplyingDocType, ApplyingDocNo);
        ApplyingCustLedgEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(ApplyingCustLedgEntry, ApplyingCustLedgEntry."Remaining Amount");
        LibraryERM.FindCustomerLedgerEntry(AppliesToCustLedgEntry, AppliesToDocType, AppliesToDocNo);
        LibraryERM.SetAppliestoIdCustomer(AppliesToCustLedgEntry);
        LibraryERM.PostCustLedgerApplication(ApplyingCustLedgEntry);
    end;

    local procedure FindCheckLedgEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountNo: Code[20]; DocType: Option; DocNo: Code[20])
    begin
        with CheckLedgerEntry do begin
            SetRange("Bank Account No.", BankAccountNo);
            SetRange("Document Type", DocType);
            SetRange("Document No.", DocNo);
            FindFirst;
        end;
    end;

    local procedure VoidCheckLedgEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; VoidType: Option)
    var
        CheckManagement: Codeunit CheckManagement;
    begin
        LibraryVariableStorage.Enqueue(VoidType);
        CheckManagement.FinancialVoidCheck(CheckLedgerEntry);
        CheckLedgerEntry.Find;
    end;

    local procedure IsGenJnlLineCashIngoing(GenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        with GenJournalLine do
            exit(
              ("Account Type" = "Account Type"::Vendor) and ("Document Type" = "Document Type"::Refund) or
              ("Account Type" = "Account Type"::Customer) and ("Document Type" = "Document Type"::Payment));
    end;

    local procedure PrintCashOrder(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate("Document No.", '');
        GenJournalLine.Modify(true);
        if IsGenJnlLineCashIngoing(GenJournalLine) then
            PrintCashIngoingOrder(GenJournalLine)
        else
            PrintCashOutgoingOrder(GenJournalLine);
        GenJournalLine.Find;
    end;

    local procedure PrintCashOutgoingOrder(GenJournalLine: Record "Gen. Journal Line")
    var
        CashOutgoingOrder: Report "Cash Outgoing Order";
    begin
        CashOutgoingOrder.SetFileNameSilent(LibraryReportValidation.GetFileName);
        GenJournalLine.SetRecFilter;
        CashOutgoingOrder.SetTableView(GenJournalLine);
        CashOutgoingOrder.UseRequestPage(false);
        CashOutgoingOrder.Run;
    end;

    local procedure PrintCashIngoingOrder(GenJournalLine: Record "Gen. Journal Line")
    var
        CashIngoingOrder: Report "Cash Ingoing Order";
    begin
        CashIngoingOrder.SetFileNameSilent(LibraryReportValidation.GetFileName);
        GenJournalLine.SetRecFilter;
        CashIngoingOrder.SetTableView(GenJournalLine);
        CashIngoingOrder.UseRequestPage(false);
        CashIngoingOrder.Run;
    end;

    local procedure VerifyVendorLedgerEntries(VendorNo: Code[20]; DocumentType: Option; ExpectedCount: Integer; IsOpen: Boolean)
    var
        DummyVendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        with DummyVendorLedgerEntry do begin
            SetRange("Vendor No.", VendorNo);
            SetRange("Document Type", DocumentType);
            SetRange(Open, IsOpen);
            Assert.RecordCount(DummyVendorLedgerEntry, ExpectedCount);
        end;
    end;

    local procedure VerifyCustomerLedgerEntries(CustomerNo: Code[20]; DocumentType: Option; ExpectedCount: Integer; IsOpen: Boolean)
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        with DummyCustLedgerEntry do begin
            SetRange("Customer No.", CustomerNo);
            SetRange("Document Type", DocumentType);
            SetRange(Open, IsOpen);
            Assert.RecordCount(DummyCustLedgerEntry, ExpectedCount);
        end;
    end;

    local procedure VerifyLastRegisterIsCorrectionEntry()
    var
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
    begin
        GLRegister.FindLast;
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        repeat
            Assert.IsTrue(GLEntry."Debit Amount" <= 0, ExpectedCorrectionEntriesErr);
            Assert.IsTrue(GLEntry."Credit Amount" <= 0, ExpectedCorrectionEntriesErr);
        until GLEntry.Next = 0;
    end;

    local procedure VerifyLastRegisterIsNotCorrectionEntry()
    var
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
    begin
        GLRegister.FindLast;
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        repeat
            Assert.IsTrue(GLEntry."Debit Amount" >= 0, ExpectedNotCorrectionEntriesErr);
            Assert.IsTrue(GLEntry."Credit Amount" >= 0, ExpectedNotCorrectionEntriesErr);
        until GLEntry.Next = 0;
    end;

    local procedure VerifyCheckLedgerEntry(CheckLedgerEntry: Record "Check Ledger Entry"; ExpectedEntryStatus: Option; ExpectedOriginalEntryStatus: Option; ExpectedStatementStatus: Option)
    begin
        with CheckLedgerEntry do begin
            Assert.AreEqual(ExpectedEntryStatus, "Entry Status", FieldCaption("Entry Status"));
            Assert.AreEqual(ExpectedOriginalEntryStatus, "Original Entry Status", FieldCaption("Original Entry Status"));
            Assert.AreEqual(ExpectedStatementStatus, "Statement Status", FieldCaption("Statement Status"));
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfirmVoidCheckMPH(var ConfirmFinVoid: TestPage "Confirm Financial Void")
    begin
        ConfirmFinVoid.VoidType.SetValue(LibraryVariableStorage.DequeueInteger);
        ConfirmFinVoid.Yes.Invoke;
    end;
}

