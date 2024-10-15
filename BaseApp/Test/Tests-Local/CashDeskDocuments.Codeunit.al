codeunit 144100 "Cash Desk Documents"
{
    // Test Cases for Cash Desks
    // 1. Test if the system allows to create a new Receipt Cash Document.
    // 2. Test if the system allows to create a new Withdrawal Cash Document.
    // 3. Test the release of Receipt Cash Document.
    // 4. Test the release of Withdrawal Cash Document.
    // 5. Test error occurs on release of Receipt Cash Document with great amount.
    // 6. Test the posting of Receipt Cash Document.
    // 7. Test the posting of Withdrawal Cash Document.
    // 8. Test the release of Withdrawal Cash Document with rounding.
    // 9. Test the posting of Withdrawal Cash Document with fixed asset.
    // 10. Check that Posted Sales Invoice was correct closing after posting Receipt Cash Document.

    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryCashDesk: Codeunit "Library - Cash Desk";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        AmountLimitErr: Label 'Cash Document Amount exceeded maximal limit %1.', Comment = '%1=Cash Desk Maximal Limit';
        CashDocNotExistErr: Label 'Cash Document is not exist.';
        PostCashDocNotExistErr: Label 'Posted Cash Document is not exist.';
        CashDocStatusErr: Label 'Status in Cash Document must be Released.';
        NoOfEntriesMustBeEqualErr: Label 'No. of Entries Must Be Equal.';
        AmountMustBePositiveErr: Label 'Amount Including VAT must be positive in Cash Document Header Cash Desk No.=''%1'',No.=''%2''.', Comment = '%1 = cash desk number, %2 = cash document number';

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReceiptCashDocumentCreation()
    var
        CashDocHdr: Record "Cash Document Header";
    begin
        // Test if the system allows to create a new Receipt Cash Document.
        CashDocumentCreation(CashDocHdr."Cash Document Type"::Receipt);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure WithdrawalCashDocumentCreation()
    var
        CashDocHdr: Record "Cash Document Header";
    begin
        // Test if the system allows to create a new Withdrawal Cash Document.
        CashDocumentCreation(CashDocHdr."Cash Document Type"::Withdrawal);
    end;

    local procedure CashDocumentCreation(CashDocType: Option)
    var
        BankAcc: Record "Bank Account";
        CashDocHdr: Record "Cash Document Header";
        CashDocLn: Record "Cash Document Line";
    begin
        // 1.Setup:
        Initialize;

        // Create Cash Desk
        CreateCashDesk(BankAcc);

        // 2.Exercise:

        // Create Withdrawal Cash Document
        CreateCashDocument(CashDocHdr, CashDocLn, CashDocType, BankAcc."No.");

        // 3.Verify:
        CashDocHdr.SetRange("Cash Desk No.", BankAcc."No.");
        Assert.IsTrue(CashDocHdr.FindFirst, CashDocNotExistErr);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReleaseReceiptCashDocument()
    var
        CashDocHdr: Record "Cash Document Header";
    begin
        // Test the release of Receipt Cash Document.
        TestReleaseCashDocument(CashDocHdr."Cash Document Type"::Receipt);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReleaseWithdrawalCashDocument()
    var
        CashDocHdr: Record "Cash Document Header";
    begin
        // Test the release of Withdrawal Cash Document.
        TestReleaseCashDocument(CashDocHdr."Cash Document Type"::Withdrawal);
    end;

    local procedure TestReleaseCashDocument(CashDocType: Option)
    var
        BankAcc: Record "Bank Account";
        CashDocHdr: Record "Cash Document Header";
        CashDocLn: Record "Cash Document Line";
    begin
        // 1.Setup:
        Initialize;

        // Create Cash Desk
        CreateCashDesk(BankAcc);

        // Create Receipt Cash Document
        CreateCashDocument(CashDocHdr, CashDocLn, CashDocType, BankAcc."No.");

        // 2.Exercise:
        ReleaseCashDocument(CashDocHdr);

        // 3.Verify:
        Assert.IsTrue(CashDocHdr.Status = CashDocHdr.Status::Released, CashDocStatusErr);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReleaseReceiptCashDocumentWithGreatAmount()
    var
        BankAcc: Record "Bank Account";
        CashDocHdr: Record "Cash Document Header";
        CashDocLn: Record "Cash Document Line";
    begin
        // Test error occurs on release of Receipt Cash Document with great amount.
        // 1.Setup:
        Initialize;

        // Create Cash Desk
        CreateCashDesk(BankAcc);

        // Create Receipt Cash Document
        CreateCashDocument(CashDocHdr, CashDocLn, CashDocHdr."Cash Document Type"::Receipt, BankAcc."No.");
        CashDocLn.Validate(Amount, BankAcc."Cash Receipt Limit" * 2); // Modify amount over the limit
        CashDocLn.Modify(true);

        // 2.Exercise:
        asserterror ReleaseCashDocument(CashDocHdr);

        // 3.Verify:
        Assert.ExpectedError(StrSubstNo(AmountLimitErr, BankAcc."Cash Receipt Limit"));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostingReceiptCashDocument()
    var
        BankAcc: Record "Bank Account";
        CashDocHdr: Record "Cash Document Header";
        CashDocLn: Record "Cash Document Line";
        PostedCashDocHdr: Record "Posted Cash Document Header";
        GLEntry: Record "G/L Entry";
        BankAccPostingGroup: Record "Bank Account Posting Group";
    begin
        // Test the posting of Receipt Cash Document.
        // 1.Setup:
        Initialize;

        // Create Cash Desk
        CreateCashDesk(BankAcc);

        // Create Receipt Cash Document
        CreateCashDocument(CashDocHdr, CashDocLn, CashDocHdr."Cash Document Type"::Receipt, BankAcc."No.");

        // 2.Exercise:

        // Post Cash Document
        PostCashDocument(CashDocHdr);

        // 3.Verify:

        // Check Posted Cash Document exist
        PostedCashDocHdr.SetRange("Cash Desk No.", BankAcc."No.");
        Assert.IsTrue(PostedCashDocHdr.FindLast, PostCashDocNotExistErr);

        GLEntry.SetCurrentKey("Document No.", "Posting Date");
        GLEntry.SetRange("Document No.", PostedCashDocHdr."No.");
        GLEntry.SetRange("Posting Date", PostedCashDocHdr."Posting Date");

        BankAccPostingGroup.Get(BankAcc."Bank Acc. Posting Group");
        GLEntry.FindSet;
        GLEntry.TestField("G/L Account No.", BankAccPostingGroup."G/L Account No.");
        GLEntry.TestField("Debit Amount", CashDocLn.Amount);

        GLEntry.Next;
        GLEntry.TestField("G/L Account No.", CashDocLn."Account No.");
        GLEntry.TestField("Credit Amount", CashDocLn.Amount);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostingWithdrawalCashDocument()
    var
        BankAcc: Record "Bank Account";
        CashDeskUser: Record "Cash Desk User";
        CashDeskEvent: Record "Cash Desk Event";
        CashDocHdr: Record "Cash Document Header";
        CashDocLn: array[2] of Record "Cash Document Line";
        BankAccPostingGroup: Record "Bank Account Posting Group";
        RoundingMethod: Record "Rounding Method";
        PostedCashDocHdr: Record "Posted Cash Document Header";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        RangeAmount: Decimal;
        i: Integer;
    begin
        // Test the posting of Withdrawal Cash Document.
        // 1.Setup:
        Initialize;

        // Create Cash Desk
        CreateBankAccountPostingGroup(BankAccPostingGroup, GetNewGLAccountNo(true));
        CreateRoundingMethod(RoundingMethod);
        CreateCashDeskBase(BankAcc, BankAccPostingGroup.Code, RoundingMethod.Code);
        CreateCashDeskUser(CashDeskUser, BankAcc."No.");

        // Create Withdrawal Cash Document
        LibraryCashDesk.CreateCashDeskEvent(
          CashDeskEvent, BankAcc."No.", CashDocHdr."Cash Document Type"::Withdrawal,
          CashDeskEvent."Account Type"::"G/L Account", GetNewGLAccountNo(true));
        LibraryCashDesk.CreateCashDocumentHeader(CashDocHdr, CashDocHdr."Cash Document Type"::Withdrawal, BankAcc."No.");

        // Create Withdrawal Cash Document Line 1
        LibraryCashDesk.CreateCashDocumentLineWithCashDeskEvent(
          CashDocLn[1], CashDocHdr, CashDeskEvent.Code, 0);
        RangeAmount := Round((BankAcc."Cash Withdrawal Limit" / 2) * (100 - CashDocLn[1]."VAT %") / 100, 1, '<');
        CashDocLn[1].Validate(Amount, LibraryRandom.RandInt(RangeAmount));
        CashDocLn[1].Modify;

        // Create Withdrawal Cash Document Line 2
        LibraryCashDesk.CreateCashDocumentLineWithCashDeskEvent(
          CashDocLn[2], CashDocHdr, CashDeskEvent.Code, LibraryRandom.RandInt(Round(BankAcc."Cash Withdrawal Limit", 1, '<')));
        RangeAmount := Round((BankAcc."Cash Withdrawal Limit" / 2) * (100 - CashDocLn[2]."VAT %") / 100, 1, '<');
        CashDocLn[2].Validate(Amount, LibraryRandom.RandInt(RangeAmount));
        CashDocLn[2].Modify;

        // 2.Exercise:

        // Post Cash Document
        PostCashDocument(CashDocHdr);

        // 3.Verify:

        // Check Posted Cash Document exist
        PostedCashDocHdr.SetRange("Cash Desk No.", BankAcc."No.");
        Assert.IsTrue(PostedCashDocHdr.FindLast, PostCashDocNotExistErr);

        // Check G/L Entry
        GLEntry.SetCurrentKey("Document No.", "Posting Date");
        GLEntry.SetRange("Document No.", PostedCashDocHdr."No.");
        GLEntry.SetRange("Posting Date", PostedCashDocHdr."Posting Date");

        PostedCashDocHdr.CalcFields("Amount Including VAT (LCY)");
        GLEntry.FindSet;
        GLEntry.TestField("G/L Account No.", BankAccPostingGroup."G/L Account No.");
        GLEntry.TestField("Credit Amount", PostedCashDocHdr."Amount Including VAT (LCY)");

        for i := 1 to 2 do begin
            FindVATPostingSetupFromGLAccount(VATPostingSetup, CashDocLn[i]."Account No.");

            GLEntry.Next;
            GLEntry.TestField("G/L Account No.", CashDocLn[i]."Account No.");
            GLEntry.TestField("Debit Amount", CashDocLn[i].Amount);

            GLEntry.Next;
            GLEntry.TestField("G/L Account No.", VATPostingSetup."Purchase VAT Account");
            GLEntry.TestField("Debit Amount", CashDocLn[i]."VAT Amount");
        end;

        // Check VAT Entry
        VATEntry.SetCurrentKey("Document No.", "Posting Date");
        VATEntry.SetRange("Document No.", PostedCashDocHdr."No.");
        VATEntry.SetRange("Posting Date", PostedCashDocHdr."Posting Date");

        VATEntry.FindSet;
        VATEntry.TestField(Base, CashDocLn[1].Amount);
        VATEntry.TestField(Amount, CashDocLn[1]."VAT Amount");

        VATEntry.Next;
        VATEntry.TestField(Base, CashDocLn[2].Amount);
        VATEntry.TestField(Amount, CashDocLn[2]."VAT Amount");
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReleaseWithdrawalCashDocumentWithRounding()
    var
        BankAcc: Record "Bank Account";
        CashDocHdr: Record "Cash Document Header";
        CashDocLn: Record "Cash Document Line";
    begin
        // Test the release of Withdrawal Cash Document with rounding.
        // 1.Setup:
        Initialize;

        // Create Cash Desk
        CreateCashDesk(BankAcc);

        // Create Withdrawal Cash Document
        CreateCashDocument(CashDocHdr, CashDocLn, CashDocHdr."Cash Document Type"::Withdrawal, BankAcc."No.");
        CashDocLn.Validate(Amount, CashDocLn.Amount - 0.1); // Modify amount to decimal number
        CashDocLn.Modify(true);

        // 2.Exercise:
        ReleaseCashDocument(CashDocHdr);

        // 3.Verify:
        CashDocLn.SetRange("Cash Desk No.", BankAcc."No.");
        CashDocLn.SetRange("Cash Document No.", CashDocHdr."No.");
        CashDocLn.SetRange("Account Type", CashDocLn."Account Type"::"G/L Account");
        CashDocLn.SetRange("Account No.", BankAcc."Debit Rounding Account");
        Assert.IsTrue(CashDocLn.FindFirst, CashDocNotExistErr);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostingWithdrawalCashDocumentWithFixedAsset()
    var
        BankAcc: Record "Bank Account";
        CashDocHdr: Record "Cash Document Header";
        CashDocLn: Record "Cash Document Line";
        PostedCashDocHdr: Record "Posted Cash Document Header";
        GLEntry: Record "G/L Entry";
        FALedgEntry: Record "FA Ledger Entry";
    begin
        // Test the posting of Withdrawal Cash Document with fixed asset.
        // 1.Setup:
        Initialize;

        // Create Cash Desk
        CreateCashDesk(BankAcc);

        // Create Withdrawal Cash Document
        CreateCashDocumentWithFixedAsset(CashDocHdr, CashDocLn, CashDocHdr."Cash Document Type"::Withdrawal, BankAcc."No.");

        // 2.Exercise:

        // Post Cash Document
        PostCashDocument(CashDocHdr);

        // 3.Verify:

        // Check Posted Cash Document exist
        PostedCashDocHdr.SetRange("Cash Desk No.", BankAcc."No.");
        Assert.IsTrue(PostedCashDocHdr.FindLast, PostCashDocNotExistErr);

        // Check G/L Entry
        GLEntry.SetCurrentKey("Document No.", "Posting Date");
        GLEntry.SetRange("Document No.", PostedCashDocHdr."No.");
        GLEntry.SetRange("Posting Date", PostedCashDocHdr."Posting Date");
        GLEntry.SetFilter("G/L Account No.", '<>%1&<>%2', BankAcc."Debit Rounding Account", BankAcc."Credit Rounding Account");
        Assert.AreEqual(3, GLEntry.Count, NoOfEntriesMustBeEqualErr);

        // FA Ledger Entry
        FALedgEntry.SetCurrentKey("Document No.", "Posting Date");
        FALedgEntry.SetRange("Document No.", PostedCashDocHdr."No.");
        FALedgEntry.SetRange("Posting Date", PostedCashDocHdr."Posting Date");
        FALedgEntry.FindLast;
        FALedgEntry.TestField("FA No.", CashDocLn."Account No.");
        FALedgEntry.TestField("FA Posting Type", FALedgEntry."FA Posting Type"::"Acquisition Cost");
        FALedgEntry.TestField(Amount, CashDocLn.Amount);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplyingSalesInvoice()
    var
        SalesHdr: Record "Sales Header";
        SalesLn: Record "Sales Line";
        BankAcc: Record "Bank Account";
        CashDocHdr: Record "Cash Document Header";
        CashDocLn: Record "Cash Document Line";
        CashDeskEvent: Record "Cash Desk Event";
        PostedCashDocHdr: Record "Posted Cash Document Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntries: TestPage "Customer Ledger Entries";
        AppliedCustomerEntries: TestPage "Applied Customer Entries";
        PostDocNo: Code[20];
    begin
        // Check that Posted Sales Invoice was correct closing after posting Receipt Cash Document.
        // 1.Setup:
        Initialize;

        // Create Sales Invoice
        CreateSalesInvoice(SalesHdr, SalesLn);

        // Post Sales Invoice
        PostDocNo := PostSalesDocument(SalesHdr);

        // Create Cash Desk
        CreateCashDesk(BankAcc);

        // Create Receipt Cash Document
        LibraryCashDesk.CreateCashDeskEvent(
          CashDeskEvent, BankAcc."No.", CashDocHdr."Cash Document Type"::Receipt,
          CashDeskEvent."Account Type"::Customer, '');
        LibraryCashDesk.CreateCashDocumentHeader(CashDocHdr, CashDocHdr."Cash Document Type"::Receipt, BankAcc."No.");

        // Create Receipt Cash Document Line
        LibraryCashDesk.CreateCashDocumentLineWithCashDeskEvent(
          CashDocLn, CashDocHdr, CashDeskEvent.Code, 0);
        CashDocLn.Validate("Account No.", SalesHdr."Bill-to Customer No.");
        CashDocLn.Modify(true);
        CashDocLn.Validate("Applies-To Doc. Type", CashDocLn."Applies-To Doc. Type"::Invoice);
        CashDocLn.Validate("Applies-To Doc. No.", PostDocNo);
        CashDocLn.Modify(true);

        // 2.Exercise:

        // Post Cash Document
        PostCashDocument(CashDocHdr);

        // 3.Verify:
        PostedCashDocHdr.SetRange("Cash Desk No.", BankAcc."No.");
        Assert.IsTrue(PostedCashDocHdr.FindLast, PostCashDocNotExistErr);

        CustLedgEntries.OpenView;
        CustLedgEntries.FILTER.SetFilter("Document No.", PostedCashDocHdr."No.");
        CustLedgEntries.FILTER.SetFilter("Posting Date", Format(PostedCashDocHdr."Posting Date"));
        CustLedgEntries.Last;
        CustLedgEntries."Customer No.".AssertEquals(SalesHdr."Bill-to Customer No.");
        CustLedgEntries.Amount.AssertEquals(-SalesLn."Amount Including VAT");

        AppliedCustomerEntries.Trap;
        CustLedgEntries.AppliedEntries.Invoke;

        AppliedCustomerEntries.Last;
        AppliedCustomerEntries."Posting Date".AssertEquals(SalesHdr."Posting Date");
        AppliedCustomerEntries."Document Type".AssertEquals(CustLedgEntry."Document Type"::Invoice);
        AppliedCustomerEntries."Document No.".AssertEquals(PostDocNo);
        AppliedCustomerEntries.Amount.AssertEquals(SalesLn."Amount Including VAT");

        AppliedCustomerEntries.OK.Invoke;
        CustLedgEntries.OK.Invoke;
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReleaseReceiptCashDocumentWithNegativeAmount()
    var
        DummyCashDocumentHeader: Record "Cash Document Header";
    begin
        // [FEATURE] [Cash desk]
        // [SCENARIO] Check that error occurs on release of Receipt Cash Document with negative amount
        ReleaseCashDocumentWithNegativeAmount(DummyCashDocumentHeader."Cash Document Type"::Receipt);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReleaseWithdrawalCashDocumentWithNegativeAmount()
    var
        DummyCashDocumentHeader: Record "Cash Document Header";
    begin
        // [FEATURE] [Cash desk]
        // [SCENARIO] Check that error occurs on release of Withdrawal Cash Document with negative amount
        ReleaseCashDocumentWithNegativeAmount(DummyCashDocumentHeader."Cash Document Type"::Withdrawal);
    end;

    local procedure ReleaseCashDocumentWithNegativeAmount(CashDocType: Option)
    var
        BankAccount: Record "Bank Account";
        CashDocumentHeader: Record "Cash Document Header";
        CashDocumentLine: Record "Cash Document Line";
    begin
        Initialize;

        // [GIVEN] Create cash desk
        CreateCashDesk(BankAccount);

        // [GIVEN] Create cash document with negative amount
        CreateCashDocument(CashDocumentHeader, CashDocumentLine, CashDocType, BankAccount."No.");
        CashDocumentLine.Validate(Amount, -CashDocumentLine.Amount);
        CashDocumentLine.Modify;

        // [WHEN] Release cash document
        asserterror ReleaseCashDocument(CashDocumentHeader);

        // [THEN] Error occur
        Assert.ExpectedError(StrSubstNo(AmountMustBePositiveErr, BankAccount."No.", CashDocumentHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCashDocumentWithoutPermissions()
    var
        BankAccount: Record "Bank Account";
        BankAccPostingGroup: Record "Bank Account Posting Group";
        CashDeskUser: Record "Cash Desk User";
        CashDocumentHeader: Record "Cash Document Header";
        RoundingMethod: Record "Rounding Method";
        PermissionErr: Label 'You don''t have permission to create Cash Document Header.';
    begin
        // [FEATURE] [Cash Desk]
        // [SCENARIO] The error must occur if the user doesn't have permisions to create a cash document.
        Initialize();

        // [GIVEN] Create Cash Desk
        CreateBankAccountPostingGroup(BankAccPostingGroup, GetNewGLAccountNo(false));
        CreateRoundingMethod(RoundingMethod);
        CreateCashDeskBase(BankAccount, BankAccPostingGroup.Code, RoundingMethod.Code);
        LibraryCashDesk.CreateCashDeskUser(CashDeskUser, BankAccount."No.", false, true, true);

        // [WHEN] Create Cash Document
        asserterror LibraryCashDesk.CreateCashDocumentHeader(
            CashDocumentHeader, CashDocumentHeader."Cash Document Type"::Receipt, BankAccount."No.");

        // [THEN] Error occur
        Assert.ExpectedError(PermissionErr);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,CashDocumentStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestVATRounding()
    var
        BankAccount: Record "Bank Account";
        CashDocumentHeader: Record "Cash Document Header";
        CashDocumentLine: Record "Cash Document Line";
        CashDocumentLineRounding: Record "Cash Document Line";
        CashDocument: TestPage "Cash Document";
        AmountNotMatchErr: Label 'Amount of rounding doesn''t match.';
    begin
        // [FEATURE] [Cash Desk]
        // [SCENARIO] The rounding amount in cash document line is recalculated only if the amount in cash document lines is changes
        Initialize();

        // [GIVEN] Create Cash Desk
        CreateCashDesk(BankAccount);

        // [GIVEN] Create Receipt Cash Document
        CreateCashDocument(CashDocumentHeader, CashDocumentLine, CashDocumentHeader."Cash Document Type"::Receipt, BankAccount."No.");

        // [GIVEN] Set Amounts Including VAT
        CashDocumentHeader.Validate("Amounts Including VAT", true);
        CashDocumentHeader.Modify();

        // [GIVEN] Set Amount to 119.71
        CashDocumentLine.Validate(Amount, 119.71);
        CashDocumentLine.Modify();

        // [WHEN] Open Cash Document Statistics
        CashDocument.OpenEdit();
        CashDocument.GoToRecord(CashDocumentHeader);
        CashDocument.Statistics.Invoke();

        // [THEN] Rounding line must be created and rounding amount must be calculated
        CashDocumentLineRounding.Reset();
        CashDocumentLineRounding.SetRange("Cash Desk No.", CashDocumentHeader."Cash Desk No.");
        CashDocumentLineRounding.SetRange("Cash Document No.", CashDocumentHeader."No.");
        CashDocumentLineRounding.SetRange("Account Type", CashDocumentLine."Account Type"::"G/L Account");
        CashDocumentLineRounding.SetFilter("Account No.", '%1|%2',
            BankAccount."Debit Rounding Account", BankAccount."Credit Rounding Account");
        CashDocumentLineRounding.SetRange("System-Created Entry", true);
        CashDocumentLineRounding.FindFirst();
        Assert.AreEqual(0.29, CashDocumentLineRounding.Amount, AmountNotMatchErr);

        // [GIVEN] Change Amount to 119.70
        CashDocumentLine.Validate(Amount, 119.70);
        CashDocumentLine.Modify();

        // [WHEN] Open Cash Document Statistics
        CashDocument.Statistics.Invoke();

        // [THEN] Amount in rounding line must be recalculated
        CashDocumentLineRounding.FindFirst();
        Assert.AreEqual(0.30, CashDocumentLineRounding.Amount, AmountNotMatchErr);

        // [WHEN] Open Cash Document Statistics again
        CashDocument.Statistics.Invoke();

        // [THEN] Amount in rounding line mustn't be recalculated but the amount must be the same as before
        CashDocumentLineRounding.FindFirst();
        Assert.AreEqual(0.30, CashDocumentLineRounding.Amount, AmountNotMatchErr);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure PaymentToleranceInCashDocument()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BankAccount: Record "Bank Account";
        CashDocumentHeader: Record "Cash Document Header";
        CashDocumentLine: Record "Cash Document Line";
        CashDeskEvent: Record "Cash Desk Event";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PaymentToleranceAmount: Decimal;
        PostDocNo: Code[20];
        MustExistErr: Label 'Detailed Customer Ledger Entry with payment tolerance must exist.';
        AmountNotMatchErr: Label 'Amount of payment tolerance doesn''t match.';
    begin
        // [FEATURE] [Cash Desk]
        // [SCENARIO] When the payment tolerance is enabled and Cash Document is applying e.g. Sales Invoice with different amount
        // which is posted by Sales Invoice then Detailed Customer Ledger Entry with payment tolerance type must be created.
        Initialize();

        // [GIVEN] Enable payment tolerance
        EnablePaymentTolerance();

        // [GIVEN] Create Sales Invoice
        CreateSalesInvoice(SalesHeader, SalesLine);

        // [GIVEN] Post Sales Invoice
        PostDocNo := PostSalesDocument(SalesHeader);

        // [GIVEN] Create Cash Desk
        CreateCashDesk(BankAccount);

        // [GIVEN] Create Receipt Cash Document
        LibraryCashDesk.CreateCashDeskEvent(
          CashDeskEvent, BankAccount."No.", CashDocumentHeader."Cash Document Type"::Receipt,
          CashDeskEvent."Account Type"::Customer, '');
        LibraryCashDesk.CreateCashDocumentHeader(CashDocumentHeader, CashDocumentHeader."Cash Document Type"::Receipt, BankAccount."No.");

        // [GIVEN] Create Receipt Cash Document Line with application to created invoice and round the amount to an integer.
        LibraryCashDesk.CreateCashDocumentLineWithCashDeskEvent(
          CashDocumentLine, CashDocumentHeader, CashDeskEvent.Code, 0);
        CashDocumentLine.Validate("Account No.", SalesHeader."Bill-to Customer No.");
        CashDocumentLine.Modify(true);
        CashDocumentLine.Validate("Applies-To Doc. Type", CashDocumentLine."Applies-To Doc. Type"::Invoice);
        CashDocumentLine.Validate("Applies-To Doc. No.", PostDocNo);
        PaymentToleranceAmount := CashDocumentLine.Amount - Round(CashDocumentLine.Amount, 1, '=');
        CashDocumentLine.Validate(Amount, Round(CashDocumentLine.Amount, 1, '='));
        CashDocumentLine.Modify(true);

        // [WHEN] Post Cash Document
        PostCashDocument(CashDocumentHeader);

        // [THEN] Detailed Customer Ledger Entry with Payment Tolerance is created
        DetailedCustLedgEntry.SetRange("Customer No.", CashDocumentLine."Account No.");
        DetailedCustLedgEntry.SetRange("Document No.", CashDocumentHeader."No.");
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Payment Tolerance");
        Assert.IsTrue(DetailedCustLedgEntry.FindFirst(), MustExistErr);
        Assert.AreEqual(-PaymentToleranceAmount, DetailedCustLedgEntry.Amount, AmountNotMatchErr);
    end;

    local procedure CreateCashDesk(var BankAcc: Record "Bank Account")
    var
        BankAccPostingGroup: Record "Bank Account Posting Group";
        RoundingMethod: Record "Rounding Method";
        CashDeskUser: Record "Cash Desk User";
    begin
        CreateBankAccountPostingGroup(BankAccPostingGroup, GetNewGLAccountNo(false));
        CreateRoundingMethod(RoundingMethod);
        CreateCashDeskBase(BankAcc, BankAccPostingGroup.Code, RoundingMethod.Code);
        CreateCashDeskUser(CashDeskUser, BankAcc."No.");
    end;

    local procedure CreateCashDeskBase(var BankAcc: Record "Bank Account"; BankAccPostingGroupCode: Code[20]; RoundingMethodCode: Code[10])
    begin
        LibraryCashDesk.CreateCashDesk(BankAcc);
        BankAcc."Confirm Inserting of Document" := true;
        BankAcc."Bank Acc. Posting Group" := BankAccPostingGroupCode;
        BankAcc."Debit Rounding Account" := GetNewGLAccountNo(false);
        BankAcc."Credit Rounding Account" := GetNewGLAccountNo(false);
        BankAcc."Rounding Method Code" := RoundingMethodCode;
        BankAcc."Cash Receipt Limit" := LibraryRandom.RandDec(10000, 2);
        BankAcc."Cash Withdrawal Limit" := LibraryRandom.RandDec(10000, 2);
        BankAcc."Max. Balance" := LibraryRandom.RandDec(10000, 2);
        BankAcc."Min. Balance" := LibraryRandom.RandDec(10000, 2);
        BankAcc."Cash Document Receipt Nos." := LibraryUtility.GetGlobalNoSeriesCode;
        BankAcc."Cash Document Withdrawal Nos." := LibraryUtility.GetGlobalNoSeriesCode;
        BankAcc.Modify(true);
    end;

    local procedure CreateCashDeskEvent(var CashDeskEvent: Record "Cash Desk Event"; CashDeskNo: Code[20]; CashDocType: Option; AccountType: Option)
    var
        AccountNo: Code[20];
    begin
        case AccountType of
            CashDeskEvent."Account Type"::"G/L Account":
                AccountNo := GetNewGLAccountNo(false);
        end;

        LibraryCashDesk.CreateCashDeskEvent(CashDeskEvent, CashDeskNo, CashDocType, AccountType, AccountNo);
    end;

    local procedure CreateCashDeskUser(var CashDeskUser: Record "Cash Desk User"; CashDeskNo: Code[20])
    begin
        LibraryCashDesk.CreateCashDeskUser(CashDeskUser, CashDeskNo, true, true, true);
    end;

    local procedure CreateBankAccountPostingGroup(var BankAccPostingGroup: Record "Bank Account Posting Group"; GLAccountNo: Code[20])
    begin
        LibraryERM.CreateBankAccountPostingGroup(BankAccPostingGroup);
        BankAccPostingGroup."G/L Account No." := GLAccountNo;
        BankAccPostingGroup.Modify(true);
    end;

    local procedure CreateRoundingMethod(var RoundingMethod: Record "Rounding Method")
    begin
        LibraryCashDesk.CreateRoundingMethod(RoundingMethod);
        RoundingMethod."Minimum Amount" := 0;
        RoundingMethod."Amount Added Before" := 0;
        RoundingMethod.Type := RoundingMethod.Type::Nearest;
        RoundingMethod.Precision := 1;
        RoundingMethod."Amount Added After" := 0;
        RoundingMethod.Modify(true);
    end;

    local procedure CreateCashDocument(var CashDocHdr: Record "Cash Document Header"; var CashDocLn: Record "Cash Document Line"; CashDocType: Option; CashDeskNo: Code[20])
    var
        BankAcc: Record "Bank Account";
        CashDeskEvent: Record "Cash Desk Event";
        CashLimit: Decimal;
        RangeAmount: Decimal;
    begin
        CreateCashDeskEvent(CashDeskEvent, CashDeskNo, CashDocType, CashDeskEvent."Account Type"::"G/L Account");
        BankAcc.Get(CashDeskNo);

        LibraryCashDesk.CreateCashDocumentHeader(CashDocHdr, CashDocType, CashDeskNo);
        case CashDocType of
            CashDocLn."Cash Document Type"::Receipt:
                CashLimit := BankAcc."Cash Receipt Limit";
            CashDocLn."Cash Document Type"::Withdrawal:
                CashLimit := BankAcc."Cash Withdrawal Limit";
        end;

        LibraryCashDesk.CreateCashDocumentLineWithCashDeskEvent(
          CashDocLn, CashDocHdr, CashDeskEvent.Code, 0);
        RangeAmount := Round(CashLimit * (100 - CashDocLn."VAT %") / 100, 1, '<');
        CashDocLn.Validate(Amount, LibraryRandom.RandInt(RangeAmount));
        CashDocLn.Modify;
    end;

    local procedure CreateCashDocumentWithFixedAsset(var CashDocHdr: Record "Cash Document Header"; var CashDocLn: Record "Cash Document Line"; CashDocType: Option; CashDeskNo: Code[20])
    var
        BankAcc: Record "Bank Account";
        CashLimit: Decimal;
        RangeAmount: Decimal;
    begin
        BankAcc.Get(CashDeskNo);

        LibraryCashDesk.CreateCashDocumentHeader(CashDocHdr, CashDocType, CashDeskNo);
        case CashDocType of
            CashDocLn."Cash Document Type"::Receipt:
                CashLimit := BankAcc."Cash Receipt Limit";
            CashDocLn."Cash Document Type"::Withdrawal:
                CashLimit := BankAcc."Cash Withdrawal Limit";
        end;
        LibraryCashDesk.CreateCashDocumentLine(
          CashDocLn, CashDocHdr, CashDocLn."Account Type"::"Fixed Asset",
          GetNewFixedAssetNo, 0);
        RangeAmount := Round(CashLimit * (100 - CashDocLn."VAT %") / 100, 1, '<');
        CashDocLn.Validate(Amount, LibraryRandom.RandInt(RangeAmount));
        CashDocLn.Validate("FA Posting Type", CashDocLn."FA Posting Type"::"Acquisition Cost");
        CashDocLn.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line")
    var
        Cust: Record Customer;
    begin
        LibrarySales.CreateCustomer(Cust);
        Cust.Validate("Application Method", Cust."Application Method"::Manual);
        Cust.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHdr, SalesHdr."Document Type"::Invoice, Cust."No.");
        LibrarySales.CreateSalesLine(
          SalesLn, SalesHdr, SalesLn.Type::"G/L Account", GetExistGLAccountNo, 1);
        SalesLn.Validate("Unit Price", LibraryRandom.RandDecInDecimalRange(1000.01, 1000.99, 2));
        SalesLn.Modify(true);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account"; WithVATPostingSetup: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccountNo: Code[20];
    begin
        if not WithVATPostingSetup then
            LibraryERM.CreateGLAccount(GLAccount)
        else begin
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
            GLAccount.Get(GLAccountNo);
        end;
    end;

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset")
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        CreateDepreciationBook(DepreciationBook);
        CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup.Code);
        FADepreciationBook.Validate("Default FA Depreciation Book", true);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFAPostingGroup(var FAPostingGroup: Record "FA Posting Group")
    begin
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        FAPostingGroup."Acquisition Cost Account" := GetExistGLAccountNo;
        FAPostingGroup."Accum. Depreciation Account" := GetExistGLAccountNo;
        FAPostingGroup."Acq. Cost Acc. on Disposal" := GetExistGLAccountNo;
        FAPostingGroup."Accum. Depr. Acc. on Disposal" := GetExistGLAccountNo;
        FAPostingGroup."Gains Acc. on Disposal" := GetExistGLAccountNo;
        FAPostingGroup."Losses Acc. on Disposal" := GetExistGLAccountNo;
        FAPostingGroup."Maintenance Expense Account" := GetExistGLAccountNo;
        FAPostingGroup."Depreciation Expense Acc." := GetExistGLAccountNo;
        FAPostingGroup.Modify(true);
    end;

    local procedure CreateDepreciationBook(var DepreciationBook: Record "Depreciation Book")
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Modify(true);
    end;

    local procedure FindGLAccount(var GLAccount: Record "G/L Account")
    begin
        LibraryERM.FindGLAccount(GLAccount);
    end;

    local procedure FindVATPostingSetupFromGLAccount(var VATPostingSetup: Record "VAT Posting Setup"; AccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(AccountNo);
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
    end;

    local procedure GetExistGLAccountNo(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        FindGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure GetNewGLAccountNo(WithVATPostingSetup: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        CreateGLAccount(GLAccount, WithVATPostingSetup);
        exit(GLAccount."No.");
    end;

    local procedure GetNewFixedAssetNo(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        CreateFixedAsset(FixedAsset);
        exit(FixedAsset."No.");
    end;

    local procedure ReleaseCashDocument(var CashDocHdr: Record "Cash Document Header")
    begin
        LibraryCashDesk.ReleaseCashDocument(CashDocHdr);
    end;

    local procedure PostCashDocument(var CashDocHdr: Record "Cash Document Header")
    begin
        LibraryCashDesk.PostCashDocument(CashDocHdr);
    end;

    local procedure PostSalesDocument(var SalesHdr: Record "Sales Header"): Code[20]
    begin
        exit(LibrarySales.PostSalesDocument(SalesHdr, true, true));
    end;

    local procedure EnablePaymentTolerance()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Max. Payment Tolerance Amount" := 1;
        GeneralLedgerSetup.Modify();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CashDocumentStatisticsModalPageHandler(var CashDocumentStatistics: TestPage "Cash Document Statistics")
    begin
    end;
}

