codeunit 134124 "ERM Reverse Employee Ledger"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Reverse] [Employee Ledger Entry]
    end;

    var
        Assert: Codeunit Assert;
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        PostedAndAppliedSameTransactionErr: Label 'You cannot reverse register number %1 because it contains customer or vendor or employee ledger entries that have been posted and applied in the same transaction.';
        DialogCodeErr: Label 'Dialog';
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    [Scope('OnPrem')]
    procedure ReversalEntryEmployeeSourceNo()
    var
        ReversalEntry: Record "Reversal Entry";
        EmployeeNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 274734] When validate "Source No." = Employee No. in Reversal Entry with Source Type Employee, then "Source No" = Employee No.

        // [GIVEN] Employee "E"
        LibraryLowerPermissions.SetOutsideO365Scope();
        EmployeeNo := LibraryHumanResource.CreateEmployeeNo;

        // [GIVEN] Reversal Entry with Source Type = Employee
        ReversalEntry.Init();
        ReversalEntry.Validate("Source Type", ReversalEntry."Source Type"::Employee);

        // [WHEN] Validate Source No. = "E" in Reversal Entry
        LibraryLowerPermissions.SetO365BusFull;
        ReversalEntry.Validate("Source No.", EmployeeNo);

        // [THEN] Source No. = "E" in Reversal Entry
        LibraryLowerPermissions.SetOutsideO365Scope();
        ReversalEntry.TestField("Source No.", EmployeeNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReversalEntryCopyFromEmployeeLedgerEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 274734] Copy from Employee Ledger Entry to Reversal Entry

        // [GIVEN] Posted Payment Gen. Journal Line for Employee "AH" (Employee Ledger Entry was created as result)
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreatePaymentForEmployeeGenJournalLineWithGLBalAccount(GenJournalLine, LibraryHumanResource.CreateEmployeeNoWithBankAccount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        EmployeeLedgerEntry.Get(FindEmplLedgEntryByEmployeeNoAndDocNo(GenJournalLine."Account No.", GenJournalLine."Document No."));
        EmployeeLedgerEntry.CalcFields(
          Amount, "Debit Amount", "Credit Amount", "Amount (LCY)", "Debit Amount (LCY)", "Credit Amount (LCY)");

        // [WHEN] Copy from Employee Ledger Entry to Reversal Entry
        LibraryLowerPermissions.SetO365BusFull;
        ReversalEntry.CopyFromEmployeeLedgerEntry(EmployeeLedgerEntry);

        // [THEN] Fields are copied from  Employee Ledger Entry to Reversal Entry
        LibraryLowerPermissions.SetOutsideO365Scope();
        with ReversalEntry do begin
            TestField("Entry No.", EmployeeLedgerEntry."Entry No.");
            TestField("Posting Date", EmployeeLedgerEntry."Posting Date");
            TestField("Source Code", EmployeeLedgerEntry."Source Code");
            TestField("Journal Batch Name", EmployeeLedgerEntry."Journal Batch Name");
            TestField("Transaction No.", EmployeeLedgerEntry."Transaction No.");
            TestField("Currency Code", EmployeeLedgerEntry."Currency Code");
            TestField(Description, EmployeeLedgerEntry.Description);
            TestField("Document Type", EmployeeLedgerEntry."Document Type");
            TestField("Document No.", EmployeeLedgerEntry."Document No.");
            TestField("Bal. Account Type", EmployeeLedgerEntry."Bal. Account Type");
            TestField("Bal. Account No.", EmployeeLedgerEntry."Bal. Account No.");
            TestField(Amount, EmployeeLedgerEntry.Amount);
            TestField("Amount (LCY)", EmployeeLedgerEntry."Amount (LCY)");
            TestField("Debit Amount", EmployeeLedgerEntry."Debit Amount");
            TestField("Debit Amount (LCY)", EmployeeLedgerEntry."Debit Amount (LCY)");
            TestField("Credit Amount", 0);
            TestField("Credit Amount (LCY)", 0);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReversalEntryCopyFromEmployeeLedgerEntryCreditAmountsCopied()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 274734] Copy from Employee Ledger Entry to Reversal Entry copies Credit Amount and Credit Amount (LCY)

        // [GIVEN] Posted Gen. Journal Line for Employee with Amount = -1000 (Employee Ledger Entry was created as result)
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateEmployeeGenJournalLineWithNegativeAmount(GenJournalLine, LibraryHumanResource.CreateEmployeeNoWithBankAccount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        EmployeeLedgerEntry.Get(FindEmplLedgEntryByEmployeeNoAndDocNo(GenJournalLine."Account No.", GenJournalLine."Document No."));
        EmployeeLedgerEntry.CalcFields("Credit Amount", "Credit Amount (LCY)");

        // [WHEN] Copy from Employee Ledger Entry to Reversal Entry
        LibraryLowerPermissions.SetO365BusFull;
        ReversalEntry.CopyFromEmployeeLedgerEntry(EmployeeLedgerEntry);

        // [THEN] Fields Credit Amount and Credit Amount (LCY) are copied from  Employee Ledger Entry to Reversal Entry
        LibraryLowerPermissions.SetOutsideO365Scope();
        with ReversalEntry do begin
            TestField("Credit Amount");
            TestField("Credit Amount (LCY)");
            TestField("Credit Amount", EmployeeLedgerEntry."Credit Amount");
            TestField("Credit Amount (LCY)", EmployeeLedgerEntry."Credit Amount (LCY)");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ViewEmployeeLedgerEntriesFromGLRegistersPage()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLRegisters: TestPage "G/L Registers";
        EmployeeLedgerEntries: TestPage "Employee Ledger Entries";
        EmplLedgEntryNo: Integer;
    begin
        // [FEATURE] [UI] [G/L Registers] [Employee Ledger Entries]
        // [SCENARIO 274734] Stan can view the Employee Ledger Entries that resulted in the G/L Register Entry on page G/L Register Entries

        // [GIVEN] Posted Payment Gen. Journal Line for Employee "AH" (G/L Registers and Employee Ledger Entry were created as result)
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreatePaymentForEmployeeGenJournalLineWithGLBalAccount(GenJournalLine, LibraryHumanResource.CreateEmployeeNoWithBankAccount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        EmplLedgEntryNo := FindEmplLedgEntryByEmployeeNoAndDocNo(GenJournalLine."Account No.", GenJournalLine."Document No.");

        // [GIVEN] Opened page G/L Registers and found last G/L Register on page
        GLRegisters.OpenEdit;
        GLRegisters.GotoKey(FindGLRegisterByEmplLedgEntry(EmplLedgEntryNo));
        EmployeeLedgerEntries.Trap;

        // [WHEN] Push "Employee Ledger" on G/L Register page ribbon
        LibraryLowerPermissions.SetO365BusFull;
        GLRegisters."Employee Ledger".Invoke;

        // [THEN] Page Employee Ledger Entries opens having Employee Ledger Entry which was created for Employee "AH"
        LibraryLowerPermissions.SetOutsideO365Scope();
        EmployeeLedgerEntries.GotoKey(EmplLedgEntryNo);
        EmployeeLedgerEntries."Employee No.".AssertEquals(GenJournalLine."Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseRegisterForEmployeePaymentWithApplicationErr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ReversalEntry: Record "Reversal Entry";
        EmplLedgEntryNo: Integer;
    begin
        // [FEATURE] [Applies-To Doc. No] [Reverse Register]
        // [SCENARIO 274734] When trying to Reverse Register for Employee Payment Gen. Journal Line posted with application then Error is shown

        // [GIVEN] Posted Payment Gen. Journal Line for Employee with Document No = "D"
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreatePaymentForEmployeeGenJournalLineWithGLBalAccount(GenJournalLine, LibraryHumanResource.CreateEmployeeNoWithBankAccount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Gen. Journal Line for the same Employee with Applied-To Doc. No = "D" (G/L Register 123 was created as result)
        CreateEmployeeGenJournalLineWithGLBalAccountAndApplyToDoc(
          GenJournalLine, GenJournalLine."Account No.", GenJournalLine."Document Type", GenJournalLine."Document No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        EmplLedgEntryNo := FindEmplLedgEntryByEmployeeNoAndDocNo(GenJournalLine."Account No.", GenJournalLine."Document No.");

        // [WHEN] Reverse G/L Register 123
        LibraryLowerPermissions.SetO365BusFull;
        asserterror ReversalEntry.ReverseRegister(FindGLRegisterByEmplLedgEntry(EmplLedgEntryNo));

        // [THEN] Error "You cannot reverse register No. 123 because it contains customer or vendor or employee ledger entries that have been posted and applied in the same transaction..."
        LibraryLowerPermissions.SetOutsideO365Scope();
        Assert.ExpectedError(StrSubstNo(PostedAndAppliedSameTransactionErr, FindGLRegisterByEmplLedgEntry(EmplLedgEntryNo)));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [HandlerFunctions('ReverseEntriesModalPageHandlerWithCheckValues')]
    [Scope('OnPrem')]
    procedure ReverseEntriesShowsReversalEntryForEmployeeLedgerEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ReversalEntry: Record "Reversal Entry";
        EmplLedgEntryNo: Integer;
    begin
        // [FEATURE] [UI] [Reverse Register]
        // [SCENARIO 274734] When Reverse Register for posted Employee Payment then Reversal Entry with "Employee" Entry Type is shown on page Reverse Entries
        // [SCENARIO 274734] and Reversal Entry with "G/L Entry" Entry Type has "Source Type" = Employee and "Source No." = Employee No.

        // [GIVEN] Posted Payment Gen. Journal Line for Employee "AH" (G/L Register was created as result)
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreatePaymentForEmployeeGenJournalLineWithGLBalAccount(GenJournalLine, LibraryHumanResource.CreateEmployeeNoWithBankAccount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        EmplLedgEntryNo := FindEmplLedgEntryByEmployeeNoAndDocNo(GenJournalLine."Account No.", GenJournalLine."Document No.");
        LibraryVariableStorage.Enqueue(EmplLedgEntryNo);

        // [WHEN] Reverse G/L Register
        LibraryLowerPermissions.SetO365BusFull;
        ReversalEntry.ReverseRegister(FindGLRegisterByEmplLedgEntry(EmplLedgEntryNo));

        // [THEN] Page Reverse Entries opens with line, having Entry Type = "Employee" and Account No. = "AH"
        // verification is done in ReverseEntriesModalPageHandlerWithCheckValues

        // [THEN] Page Reverse Entries has another line with Entry Type = "G/L Entry", having "Source Type" = Employee and "Source No." = "AH"
        // verification is done in ReverseEntriesModalPageHandlerWithCheckValues
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ReverseEntriesModalPageHandlerWithCheckValues')]
    [Scope('OnPrem')]
    procedure ReverseTransactionShowsReversalEntryForEmployeeLedgerEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EmployeeLedgerEntries: TestPage "Employee Ledger Entries";
        EmplLedgEntryNo: Integer;
    begin
        // [FEATURE] [UI] [Reverse Transaction]
        // [SCENARIO 274734] When Reverse Transaction is called from Employee Ledger Entries page then Reversal Entries are shown on Reversal Entries page

        // [GIVEN] Posted Payment Gen. Journal Line for Employee "AH" (Employee Ledger Entry was created as result)
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreatePaymentForEmployeeGenJournalLineWithGLBalAccount(GenJournalLine, LibraryHumanResource.CreateEmployeeNoWithBankAccount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        EmplLedgEntryNo := FindEmplLedgEntryByEmployeeNoAndDocNo(GenJournalLine."Account No.", GenJournalLine."Document No.");

        // [GIVEN] Opened page Employee Ledger Entries and find last Employee Ledger Entry on page
        EmployeeLedgerEntries.OpenView;
        EmployeeLedgerEntries.GotoKey(EmplLedgEntryNo);
        LibraryVariableStorage.Enqueue(EmplLedgEntryNo);

        // [WHEN] Push Reverse Transaction on page Employee Ledger Entries ribbon
        LibraryLowerPermissions.SetO365BusFull;
        EmployeeLedgerEntries.ReverseTransaction.Invoke;

        // [THEN] Page Reverse Entries opens with line, having Entry Type = "Employee" and Account No. = "AH"
        // verification is done in ReverseEntriesModalPageHandlerWithCheckValues

        // [THEN] Page Reverse Entries has line with Entry Type = "G/L Entry", having "Source Type" = Employee and "Source No." = "AH"
        // verification is done in ReverseEntriesModalPageHandlerWithCheckValues

        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ReverseEntriesModalPageHandlerSimple,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseEmployeeLedgerEntryWhenEmployeePaymentPosted()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ReversalEntry: Record "Reversal Entry";
        EmplLedgEntryNo: Integer;
    begin
        // [FEATURE] [Reverse Register]
        // [SCENARIO 274734] Verifies reversal of Employee Ledger Entry when Employee Payment Gen. Journal Line is posted

        // [GIVEN] Posted Payment Gen. Journal Line for Employee "AH" with Amount = 1000.0
        // [GIVEN] (G/L Register, Employee Ledger Entry 100 and Detailed Employee Ledger Entry 200 were created as result)
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreatePaymentForEmployeeGenJournalLineWithGLBalAccount(GenJournalLine, LibraryHumanResource.CreateEmployeeNoWithBankAccount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        EmplLedgEntryNo := FindEmplLedgEntryByEmployeeNoAndDocNo(GenJournalLine."Account No.", GenJournalLine."Document No.");

        // [GIVEN] Reverse G/L Register
        LibraryLowerPermissions.SetO365BusFull;
        ReversalEntry.ReverseRegister(FindGLRegisterByEmplLedgEntry(EmplLedgEntryNo));

        // [GIVEN] Page Reverse Entries opened with Employee type Reversal Entry

        // [WHEN] Push Reverse on page ribbon
        // done in ReverseEntriesModalPageHandlerSimple

        // [THEN] Employee Ledger Entry 105 with "Closed by Entry No." = 100 with Employee "AH" and Amount = -1000.0 is created
        LibraryLowerPermissions.SetOutsideO365Scope();
        VerifyReversalEmployeeLedgerEntry(EmplLedgEntryNo);

        // [THEN] Employee Ledger Entry 100 is closed by Entry No 105 by Amount = 1000.0
        VerifyOriginalEmployeeLedgerEntryAppliedFields(EmplLedgEntryNo);

        // [THEN] Detailed Employee Ledger Entry 201 for Employee "AH" is created for entry 105 with Type "Initial Entry" and Amount = -1000.0
        VerifyReversalDetailedEmployeeLedgerEntry(EmplLedgEntryNo);

        // [THEN] Balancing Detailed Employee Ledger Entry 202 for Employee "AH" is created for entry 100 with Type "Application" and Amount = -1000.0
        VerifyBalancingDetailedEmployeeLedgerEntry(EmplLedgEntryNo);

        // [THEN] Balancing Detailed Employee Ledger Entry 203 for Employee "AH" is created for entry 105 with Type "Application" and Amount = 1000.0
        VerifyBalancingReversalDetailedEmployeeLedgerEntry(EmplLedgEntryNo);
    end;

    [Test]
    [HandlerFunctions('ReverseEntriesModalPageHandlerSimple,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseEmployeeLedgerEntryWhenEmployeeCreditLinePosted()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ReversalEntry: Record "Reversal Entry";
        EmplLedgEntryNo: Integer;
    begin
        // [FEATURE] [Reverse Register]
        // [SCENARIO 274734] Verifies reversal of Employee Ledger Entry when Employee Gen. Journal Line is posted with <negative> Amount

        // [GIVEN] Posted Gen. Journal Line for Employee "AH" with Amount = -1000.0
        // [GIVEN] (G/L Register, Employee Ledger Entry 100 and Detailed Employee Ledger Entry 200 were created as result)
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateEmployeeGenJournalLineWithNegativeAmount(GenJournalLine, LibraryHumanResource.CreateEmployeeNoWithBankAccount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        EmplLedgEntryNo := FindEmplLedgEntryByEmployeeNoAndDocNo(GenJournalLine."Account No.", GenJournalLine."Document No.");

        // [GIVEN] Reverse G/L Register
        LibraryLowerPermissions.SetO365BusFull;
        ReversalEntry.ReverseRegister(FindGLRegisterByEmplLedgEntry(EmplLedgEntryNo));

        // [GIVEN] Page Reverse Entries opened with Employee type Reversal Entry

        // [WHEN] Push Reverse on page ribbon
        // done in ReverseEntriesModalPageHandlerSimple

        // [THEN] Employee Ledger Entry 105 with "Closed by Entry No." = 100 with Employee "AH" and Amount = 1000.0 is created
        LibraryLowerPermissions.SetOutsideO365Scope();
        VerifyReversalEmployeeLedgerEntry(EmplLedgEntryNo);

        // [THEN] Employee Ledger Entry 100 is closed by Entry No 105 by Amount = -1000.0
        VerifyOriginalEmployeeLedgerEntryAppliedFields(EmplLedgEntryNo);

        // [THEN] Detailed Employee Ledger Entry 201 for Employee "AH" is created for entry 105 with Type "Initial Entry" and Amount = 1000.0
        VerifyReversalDetailedEmployeeLedgerEntry(EmplLedgEntryNo);

        // [THEN] Balancing Detailed Employee Ledger Entry 202 for Employee "AH" is created for entry 100 with Type "Application" and Amount = 1000.0
        VerifyBalancingDetailedEmployeeLedgerEntry(EmplLedgEntryNo);

        // [THEN] Balancing Detailed Employee Ledger Entry 203 for Employee "AH" is created for entry 105 with Type "Application" and Amount = -1000.0
        VerifyBalancingReversalDetailedEmployeeLedgerEntry(EmplLedgEntryNo);
    end;

    local procedure CreateEmployeeGenJournalLineWithGLBalAccountAndApplyToDoc(var GenJournalLine: Record "Gen. Journal Line"; EmployeeNo: Code[20]; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20])
    begin
        CreateEmployeeGenJournalLineWithNegativeAmount(GenJournalLine, EmployeeNo);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateEmployeeGenJournalLineWithNegativeAmount(var GenJournalLine: Record "Gen. Journal Line"; EmployeeNo: Code[20])
    begin
        CreateGenJournalLineWithBalAccount(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Employee,
          EmployeeNo, GenJournalLine."Bal. Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo, -LibraryRandom.RandDecInRange(1000, 2000, 2));
    end;

    local procedure CreatePaymentForEmployeeGenJournalLineWithGLBalAccount(var GenJournalLine: Record "Gen. Journal Line"; EmployeeNo: Code[20])
    begin
        CreateGenJournalLineWithBalAccount(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Employee,
          EmployeeNo, GenJournalLine."Bal. Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo, LibraryRandom.RandDecInRange(1000, 2000, 2));
    end;

    local procedure CreateGenJournalLineWithBalAccount(var GenJournalLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; BalAccType: Enum "Gen. Journal Account Type"; BalAccNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocType, AccType, AccNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", BalAccType);
        GenJournalLine.Validate("Bal. Account No.", BalAccNo);
        GenJournalLine.Modify(true);
    end;

    local procedure GetSourceCodeSetupReversal(): Code[10]
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        exit(SourceCodeSetup.Reversal);
    end;

    local procedure FindEmplLedgEntryByEmployeeNoAndDocNo(EmployeeNo: Code[20]; DocNo: Code[20]): Integer
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
        EmployeeLedgerEntry.SetRange("Document No.", DocNo);
        EmployeeLedgerEntry.FindFirst();
        exit(EmployeeLedgerEntry."Entry No.");
    end;

    local procedure FindReversalEmployeeLedgerEntryNoByOriginalEntryNo(OriginalEmployeeLedgerEntryNo: Integer): Integer
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.SetRange("Closed by Entry No.", OriginalEmployeeLedgerEntryNo);
        EmployeeLedgerEntry.FindFirst();
        exit(EmployeeLedgerEntry."Entry No.");
    end;

    local procedure FindGLRegisterByEmplLedgEntry(EmplLedgEntryNo: Integer): Integer
    var
        GLRegister: Record "G/L Register";
    begin
        GLRegister.SetRange("From Entry No.", EmplLedgEntryNo);
        GLRegister.FindFirst();
        exit(GLRegister."No.");
    end;

    local procedure FindEmployeeLedgerEntriesAndCalcFields(var OriginalEmployeeLedgerEntry: Record "Employee Ledger Entry"; var ReversalEmployeeLedgerEntry: Record "Employee Ledger Entry"; OriginalEntryNo: Integer)
    begin
        OriginalEmployeeLedgerEntry.Get(OriginalEntryNo);
        ReversalEmployeeLedgerEntry.SetRange("Closed by Entry No.", OriginalEntryNo);
        ReversalEmployeeLedgerEntry.FindFirst();
        CalcFieldsEmplLedgEntry(OriginalEmployeeLedgerEntry);
        CalcFieldsEmplLedgEntry(ReversalEmployeeLedgerEntry);
    end;

    local procedure FindDetailedEmployeeLedgerEntry(var DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry"; EntryType: Integer; EmployeeLedgerEntryNo: Integer)
    begin
        DetailedEmployeeLedgerEntry.SetRange("Employee Ledger Entry No.", EmployeeLedgerEntryNo);
        DetailedEmployeeLedgerEntry.SetRange("Entry Type", EntryType);
        DetailedEmployeeLedgerEntry.FindFirst();
    end;

    local procedure CalcFieldsEmplLedgEntry(var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        EmployeeLedgerEntry.CalcFields(
          Amount, "Amount (LCY)", "Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)",
          "Original Amount", "Original Amt. (LCY)", "Remaining Amount", "Remaining Amt. (LCY)");
    end;

    local procedure VerifyReversalEmployeeLedgerEntry(OriginalEntryNo: Integer)
    var
        ReversalEmployeeLedgerEntry: Record "Employee Ledger Entry";
        OriginalEmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        FindEmployeeLedgerEntriesAndCalcFields(OriginalEmployeeLedgerEntry, ReversalEmployeeLedgerEntry, OriginalEntryNo);
        VerifyCalcFieldsReversalEmployeeLedgerEntry(ReversalEmployeeLedgerEntry, OriginalEmployeeLedgerEntry);
        VerifyReversalEmployeeLedgerEntryAppliedFields(ReversalEmployeeLedgerEntry, OriginalEmployeeLedgerEntry);
        with ReversalEmployeeLedgerEntry do begin
            TestField(Positive, not OriginalEmployeeLedgerEntry.Positive);
            TestField("User ID", UserId);
            TestField("Transaction No.", OriginalEmployeeLedgerEntry."Transaction No." + 1);
            TestField("Journal Batch Name", '');
            TestField("Source Code", GetSourceCodeSetupReversal);
            TestField(Description, OriginalEmployeeLedgerEntry.Description);
            TestField("Reversed Entry No.", OriginalEmployeeLedgerEntry."Entry No.");
            TestField(Reversed, true);
            TestField("Applies-to ID", '');
            TestField("Posting Date", OriginalEmployeeLedgerEntry."Posting Date");

            TestField("Employee No.", OriginalEmployeeLedgerEntry."Employee No.");
            TestField("Employee Posting Group", OriginalEmployeeLedgerEntry."Employee Posting Group");
            TestField("Document Type", OriginalEmployeeLedgerEntry."Document Type");
            TestField("Document No.", OriginalEmployeeLedgerEntry."Document No.");
            TestField("Bal. Account Type", OriginalEmployeeLedgerEntry."Bal. Account Type");
            TestField("Bal. Account No.", OriginalEmployeeLedgerEntry."Bal. Account No.");
            TestField("Currency Code", OriginalEmployeeLedgerEntry."Currency Code");
        end;
    end;

    local procedure VerifyCalcFieldsReversalEmployeeLedgerEntry(ReversalEmployeeLedgerEntry: Record "Employee Ledger Entry"; OriginalEmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        with ReversalEmployeeLedgerEntry do begin
            TestField(Amount, -OriginalEmployeeLedgerEntry.Amount);
            TestField("Amount (LCY)", -OriginalEmployeeLedgerEntry."Amount (LCY)");
            TestField("Debit Amount", -OriginalEmployeeLedgerEntry."Debit Amount");
            TestField("Debit Amount (LCY)", -OriginalEmployeeLedgerEntry."Debit Amount (LCY)");
            TestField("Credit Amount", -OriginalEmployeeLedgerEntry."Credit Amount");
            TestField("Credit Amount (LCY)", -OriginalEmployeeLedgerEntry."Credit Amount (LCY)");
            TestField("Original Amount", -OriginalEmployeeLedgerEntry."Original Amount");
            TestField("Original Amt. (LCY)", -OriginalEmployeeLedgerEntry."Original Amt. (LCY)");
            TestField("Remaining Amount", 0);
            TestField("Remaining Amt. (LCY)", 0);
        end;
    end;

    local procedure VerifyReversalEmployeeLedgerEntryAppliedFields(ReversalEmployeeLedgerEntry: Record "Employee Ledger Entry"; OriginalEmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        with ReversalEmployeeLedgerEntry do begin
            TestField("Closed by Entry No.", OriginalEmployeeLedgerEntry."Entry No.");
            TestField("Closed at Date", OriginalEmployeeLedgerEntry."Posting Date");
            TestField("Closed by Amount", -OriginalEmployeeLedgerEntry."Remaining Amount");
            TestField("Closed by Amount (LCY)", -OriginalEmployeeLedgerEntry."Remaining Amt. (LCY)");
            TestField(Open, false);
        end;
    end;

    local procedure VerifyOriginalEmployeeLedgerEntryAppliedFields(OriginalEntryNo: Integer)
    var
        OriginalEmployeeLedgerEntry: Record "Employee Ledger Entry";
        ReversalEmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        FindEmployeeLedgerEntriesAndCalcFields(OriginalEmployeeLedgerEntry, ReversalEmployeeLedgerEntry, OriginalEntryNo);
        with OriginalEmployeeLedgerEntry do begin
            TestField("Closed by Entry No.", ReversalEmployeeLedgerEntry."Entry No.");
            TestField("Closed at Date", ReversalEmployeeLedgerEntry."Posting Date");
            TestField("Closed by Amount", -ReversalEmployeeLedgerEntry.Amount);
            TestField("Closed by Amount (LCY)", -ReversalEmployeeLedgerEntry."Amount (LCY)");
            TestField(Open, false);
        end;
    end;

    local procedure VerifyReversalDetailedEmployeeLedgerEntry(OriginalEmployeeLedgerEntryNo: Integer)
    var
        OriginalDetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
        ReversalDetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
    begin
        FindDetailedEmployeeLedgerEntry(
          OriginalDetailedEmployeeLedgerEntry, OriginalDetailedEmployeeLedgerEntry."Entry Type"::"Initial Entry",
          OriginalEmployeeLedgerEntryNo);
        FindDetailedEmployeeLedgerEntry(
          ReversalDetailedEmployeeLedgerEntry, ReversalDetailedEmployeeLedgerEntry."Entry Type"::"Initial Entry",
          FindReversalEmployeeLedgerEntryNoByOriginalEntryNo(OriginalEmployeeLedgerEntryNo));

        with ReversalDetailedEmployeeLedgerEntry do begin
            TestField(Amount, -OriginalDetailedEmployeeLedgerEntry.Amount);
            TestField("Amount (LCY)", -OriginalDetailedEmployeeLedgerEntry."Amount (LCY)");
            TestField("User ID", UserId);
            TestField("Transaction No.", OriginalDetailedEmployeeLedgerEntry."Transaction No." + 1);
            TestField("Entry No.", OriginalDetailedEmployeeLedgerEntry."Entry No." + 1);
        end;
    end;

    local procedure VerifyBalancingDetailedEmployeeLedgerEntry(OriginalEmployeeLedgerEntryNo: Integer)
    var
        OriginalDetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
        BalancingDetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
    begin
        FindDetailedEmployeeLedgerEntry(
          OriginalDetailedEmployeeLedgerEntry, OriginalDetailedEmployeeLedgerEntry."Entry Type"::"Initial Entry",
          OriginalEmployeeLedgerEntryNo);
        FindDetailedEmployeeLedgerEntry(
          BalancingDetailedEmployeeLedgerEntry, BalancingDetailedEmployeeLedgerEntry."Entry Type"::Application,
          OriginalEmployeeLedgerEntryNo);

        with BalancingDetailedEmployeeLedgerEntry do begin
            TestField("Applied Empl. Ledger Entry No.", FindReversalEmployeeLedgerEntryNoByOriginalEntryNo(OriginalEmployeeLedgerEntryNo));
            TestField(Amount, -OriginalDetailedEmployeeLedgerEntry.Amount);
            TestField("Amount (LCY)", -OriginalDetailedEmployeeLedgerEntry."Amount (LCY)");
            TestField("User ID", UserId);
            TestField("Transaction No.", OriginalDetailedEmployeeLedgerEntry."Transaction No." + 1);
            TestField("Entry No.", OriginalDetailedEmployeeLedgerEntry."Entry No." + 2);
        end;
    end;

    local procedure VerifyBalancingReversalDetailedEmployeeLedgerEntry(OriginalEmployeeLedgerEntryNo: Integer)
    var
        ReversalDetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
        BalancingDetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
    begin
        FindDetailedEmployeeLedgerEntry(
          ReversalDetailedEmployeeLedgerEntry, ReversalDetailedEmployeeLedgerEntry."Entry Type"::"Initial Entry",
          FindReversalEmployeeLedgerEntryNoByOriginalEntryNo(OriginalEmployeeLedgerEntryNo));
        FindDetailedEmployeeLedgerEntry(
          BalancingDetailedEmployeeLedgerEntry, BalancingDetailedEmployeeLedgerEntry."Entry Type"::Application,
          FindReversalEmployeeLedgerEntryNoByOriginalEntryNo(OriginalEmployeeLedgerEntryNo));

        with BalancingDetailedEmployeeLedgerEntry do begin
            TestField("Applied Empl. Ledger Entry No.", ReversalDetailedEmployeeLedgerEntry."Employee Ledger Entry No.");
            TestField(Amount, -ReversalDetailedEmployeeLedgerEntry.Amount);
            TestField("Amount (LCY)", -ReversalDetailedEmployeeLedgerEntry."Amount (LCY)");
            TestField("User ID", UserId);
            TestField("Transaction No.", ReversalDetailedEmployeeLedgerEntry."Transaction No.");
            TestField("Entry No.", ReversalDetailedEmployeeLedgerEntry."Entry No." + 2);
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReverseEntriesModalPageHandlerWithCheckValues(var ReverseTransactionEntries: TestPage "Reverse Transaction Entries")
    var
        DummyReversalEntry: Record "Reversal Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.Get(LibraryVariableStorage.DequeueInteger);
        EmployeeLedgerEntry.CalcFields("Amount (LCY)");
        // Account Name, G/L Register No., Source Code, Amount, Debit and Credit Amount, Debit and Credit Amount (LCY) are invisible on page
        // Reversal Type and Line No. do not present on page;
        with ReverseTransactionEntries do begin
            FILTER.SetFilter("Entry Type", Format(DummyReversalEntry."Entry Type"::Employee));
            First;
            "Entry No.".AssertEquals(EmployeeLedgerEntry."Entry No.");
            "Posting Date".AssertEquals(EmployeeLedgerEntry."Posting Date");
            "Journal Batch Name".AssertEquals(EmployeeLedgerEntry."Journal Batch Name");
            "Transaction No.".AssertEquals(EmployeeLedgerEntry."Transaction No.");
            "Currency Code".AssertEquals(EmployeeLedgerEntry."Currency Code");
            Description.AssertEquals(EmployeeLedgerEntry.Description);
            "Amount (LCY)".AssertEquals(EmployeeLedgerEntry."Amount (LCY)");
            "Document Type".AssertEquals(EmployeeLedgerEntry."Document Type");
            "Document No.".AssertEquals(EmployeeLedgerEntry."Document No.");
            "Account No.".AssertEquals(EmployeeLedgerEntry."Employee No.");

            FILTER.SetFilter("Entry Type", Format(DummyReversalEntry."Entry Type"::"G/L Account"));
            First;
            "Source Type".AssertEquals(DummyReversalEntry."Source Type"::Employee);
            "Source No.".AssertEquals(EmployeeLedgerEntry."Employee No.");

            OK.Invoke;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReverseEntriesModalPageHandlerSimple(var ReverseTransactionEntries: TestPage "Reverse Transaction Entries")
    begin
        ReverseTransactionEntries.Reverse.Invoke;
    end;
}

