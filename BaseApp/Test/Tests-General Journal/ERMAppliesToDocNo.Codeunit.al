codeunit 134930 "ERM Applies-To Doc. No."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Applies-To Doc. No.] [General Journal]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [Scope('OnPrem')]
    procedure DocTypeChangedFromBlankToPaymentWhenValidateApplToDocNoWithInvoiceDocType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 259808] "Document Type" is changed from blank to "Payment" when validate "Applies-To Doc. No." = Posted Sales Invoice "No." in General Journal Line.

        // [GIVEN] Posted Sales Invoice "I".
        // [GIVEN] Gen. Journal Line with blank "Document Type".
        PrepareGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer,
          GenJournalLine."Applies-to Doc. Type"::Invoice, PostedDocNo, 1);

        // [WHEN] Validate "Applies-To Doc. No." = "I".
        GenJournalLine.Validate("Applies-to Doc. No.", PostedDocNo);

        // [THEN] "Document Type" = "Payment" in Gen. Journal Line.
        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocTypeNotChangedFromNonBlankWhenValidateApplToDocNoWithInvoiceDocType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 259808] "Document Type" is not changed from non-blank when validate "Applies-To Doc. No." = Posted Sales Invoice "No." in General Journal Line.

        // [GIVEN] Posted Sales Invoice "I".
        // [GIVEN] Gen. Journal Line with non-blank "Document Type".
        PrepareGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Customer,
          GenJournalLine."Applies-to Doc. Type"::Invoice, PostedDocNo, 1);

        // [WHEN] Validate "Applies-To Doc. No." = "I".
        GenJournalLine.Validate("Applies-to Doc. No.", PostedDocNo);

        // [THEN] "Document Type" is not changed in Gen. Journal Line.
        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Refund);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocTypeChangedFromBlankToPaymentWhenValidateApplToDocNoWithRefundDocType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Refund]
        // [SCENARIO 259808] "Document Type" is changed from blank to "Payment" when validate "Applies-To Doc. No." = Posted Refund "No." in General Journal Line.

        // [GIVEN] Posted Refund "R".
        // [GIVEN] Gen. Journal Line with blank "Document Type".
        PrepareGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer,
          GenJournalLine."Applies-to Doc. Type"::Refund, PostedDocNo, 1);

        // [WHEN] Validate "Applies-To Doc. No." = "R".
        GenJournalLine.Validate("Applies-to Doc. No.", PostedDocNo);

        // [THEN] "Document Type" = "Payment" in Gen. Journal Line.
        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocTypeNotChangedFromNonBlankWhenValidateApplToDocNoWithRefundDocType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Refund]
        // [SCENARIO 259808] "Document Type" is not changed from non-blank when validate "Applies-To Doc. No." = Posted Refund "No." in General Journal Line.

        // [GIVEN] Posted Refund "R".
        // [GIVEN] Gen. Journal Line with non-blank "Document Type".
        PrepareGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer,
          GenJournalLine."Applies-to Doc. Type"::Refund, PostedDocNo, 1);

        // [WHEN] Validate "Applies-To Doc. No." = "I".
        GenJournalLine.Validate("Applies-to Doc. No.", PostedDocNo);

        // [THEN] "Document Type" is not changed in Gen. Journal Line.
        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocTypeChangedFromBlankToRefundWhenValidateApplToDocNoWithCreditMemoDocType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 259808] "Document Type" is changed from blank to "Refund" when validate "Applies-To Doc. No." = Posted Credit Memo "No." in General Journal Line.

        // [GIVEN] Posted Credit Memo "CM".
        // [GIVEN] Gen. Journal Line with blank "Document Type".
        PrepareGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer,
          GenJournalLine."Applies-to Doc. Type"::"Credit Memo", PostedDocNo, -1);

        // [WHEN] Validate "Applies-To Doc. No." = "CM".
        GenJournalLine.Validate("Applies-to Doc. No.", PostedDocNo);

        // [THEN] "Document Type" = "Refund" in Gen. Journal Line.
        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Refund);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocTypeNotChangedFromNonBlankWhenValidateApplToDocNoWithCreditMemoDocType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 259808] "Document Type" is not changed from non-blank when validate "Applies-To Doc. No." = Posted Credit Memo "No." in General Journal Line.

        // [GIVEN] Posted Credit Memo "CM".
        // [GIVEN] Gen. Journal Line with non-blank "Document Type".
        PrepareGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
          GenJournalLine."Applies-to Doc. Type"::"Credit Memo", PostedDocNo, -1);

        // [WHEN] Validate "Applies-To Doc. No." = "I".
        GenJournalLine.Validate("Applies-to Doc. No.", PostedDocNo);

        // [THEN] "Document Type" is not changed in Gen. Journal Line.
        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocTypeChangedFromBlankToInvoiceWhenValidateApplToDocNoWithPaymentDocType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Payment]
        // [SCENARIO 259808] "Document Type" is changed from blank to "Invoice" when validate "Applies-To Doc. No." = Posted Payment "No." in General Journal Line.

        // [GIVEN] Posted Payment "P".
        // [GIVEN] Gen. Journal Line with blank "Document Type".
        PrepareGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer,
          GenJournalLine."Applies-to Doc. Type"::Payment, PostedDocNo, -1);

        // [WHEN] Validate "Applies-To Doc. No." = "P".
        GenJournalLine.Validate("Applies-to Doc. No.", PostedDocNo);

        // [THEN] "Document Type" = "Invoice" in Gen. Journal Line.
        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocTypeNotChangedFromNonBlankWhenValidateApplToDocNoWithPaymentDocType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Payment]
        // [SCENARIO 259808] "Document Type" is not changed from non-blank when validate "Applies-To Doc. No." = Posted Payment "No." in General Journal Line.

        // [GIVEN] Posted Payment "P".
        // [GIVEN] Gen. Journal Line with non-blank "Document Type".
        PrepareGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Customer,
          GenJournalLine."Applies-to Doc. Type"::Payment, PostedDocNo, -1);

        // [WHEN] Validate "Applies-To Doc. No." = "P".
        GenJournalLine.Validate("Applies-to Doc. No.", PostedDocNo);

        // [THEN] "Document Type" is not changed in Gen. Journal Line.
        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Refund);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesSelectDocModalPageHandler')]
    [Scope('OnPrem')]
    procedure DocTypeChangedFromBlankToPaymentForCustAccTypeWhenLookUpApplToDocNoWithInvoiceDocType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedDocType: Option;
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Lookup]
        // [SCENARIO 259808] "Document Type" is changed from blank to "Payment" when Lookup "Applies-To Doc. No." = Posted Invoice "No." for Customer Account Type on General Journal page.

        // [GIVEN] Posted Sales Invoice "I".
        // [GIVEN] Gen. Journal Line "J" with blank "Document Type" and "Account Type" = Customer.
        PostedDocType := GenJournalLine."Applies-to Doc. Type"::Invoice;
        PrepareGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer,
          PostedDocType, PostedDocNo, 1);

        // [WHEN] Select line "J" and Lookup "Applies-To Doc. No." = "I" on General Journal page.
        LibraryVariableStorage.Enqueue(PostedDocType);
        LibraryVariableStorage.Enqueue(PostedDocNo);
        GenJournalLine.LookUpAppliesToDocCust('');

        // [THEN] "Document Type" = "Payment" for line "J" on General Journal page.
        // [THEN] "Applies-to Doc. Type" = "Document Type" of posted document "I" for line "J".
        // [THEN] "Applies-to Doc. No." = "Document No." of posted document "I" for line "J".
        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.TestField("Applies-to Doc. Type", PostedDocType);
        GenJournalLine.TestField("Applies-to Doc. No.", PostedDocNo);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesSelectDocModalPageHandler')]
    [Scope('OnPrem')]
    procedure DocTypeChangedFromBlankToPaymentForVendAccTypeWhenLookUpApplToDocNoWithInvoiceDocType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedDocType: Option;
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Lookup]
        // [SCENARIO 259808] "Document Type" is changed from blank to "Payment" when Lookup "Applies-To Doc. No." = Posted Invoice "No." for Vendor Account Type on General Journal page.

        // [GIVEN] Posted Purchase Invoice "I".
        // [GIVEN] Gen. Journal Line "J" with blank "Document Type" and "Account Type" = Vendor.
        PostedDocType := GenJournalLine."Applies-to Doc. Type"::Invoice;
        PrepareGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Vendor,
          PostedDocType, PostedDocNo, -1);

        // [WHEN] Select line "J" and Lookup "Applies-To Doc. No." = "I" on General Journal page.
        LibraryVariableStorage.Enqueue(PostedDocType);
        LibraryVariableStorage.Enqueue(PostedDocNo);
        GenJournalLine.LookUpAppliesToDocVend('');

        // [THEN] "Document Type" = "Payment" for line "J" on General Journal page.
        // [THEN] "Applies-to Doc. Type" = "Document Type" of posted document "I" for line "J".
        // [THEN] "Applies-to Doc. No." = "Document No." of posted document "I" for line "J".
        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.TestField("Applies-to Doc. Type", PostedDocType);
        GenJournalLine.TestField("Applies-to Doc. No.", PostedDocNo);
    end;

    [Test]
    [HandlerFunctions('ApplyEmployeeEntriesSelectDocModalPageHandler')]
    [Scope('OnPrem')]
    procedure DocTypeNotChangedFromBlankForEmplAccTypeWhenLookUpApplToDocNoWithPaymentDocType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedDocType: Option;
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Payment] [Lookup]
        // [SCENARIO 259808] "Document Type" is not changed from blank when Lookup "Applies-To Doc. No." = Posted Payment "No." for Employee Account Type on General Journal page.

        // [GIVEN] Posted Payment "P".
        // [GIVEN] Gen. Journal Line "J" with blank "Document Type" and "Account Type" = Employee.
        PostedDocType := GenJournalLine."Applies-to Doc. Type"::Payment;
        PrepareGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Employee,
          PostedDocType, PostedDocNo, 1);

        // [WHEN] Select line "J" and Lookup "Applies-To Doc. No." = "P" on General Journal page.
        LibraryVariableStorage.Enqueue(PostedDocType);
        LibraryVariableStorage.Enqueue(PostedDocNo);
        GenJournalLine.LookUpAppliesToDocEmpl('');

        // [THEN] "Document Type" is empty for line "J" on General Journal page.
        // [THEN] "Applies-to Doc. Type" = "Document Type" of posted document "P" for line "J".
        // [THEN] "Applies-to Doc. No." = "Document No." of posted document "P" for line "J".
        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::" ");
        GenJournalLine.TestField("Applies-to Doc. Type", PostedDocType);
        GenJournalLine.TestField("Applies-to Doc. No.", PostedDocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BalAccountTypeNotChangedWhenValidateApplyToDocNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 275071] Bal. Account Type is not changed when validate Applies-to Doc. No. in Payment Line
        DocNo := LibraryUtility.GenerateGUID;

        // [GIVEN] Cust. Ledger Entry with Document No. = "D"
        MockCustLedgerEntryWithDocNo(DocNo);

        // [GIVEN] Payment Line with Bal. Account Type = "Bank Account" and Account Type = Customer
        CreatePaymentLineWithAccountTypeAndBalAccountType(
          GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Bal. Account Type"::"Bank Account");

        // [WHEN] Validate Applies-to Doc. No. = "D" in Payment Line
        GenJournalLine.Validate("Applies-to Doc. No.", DocNo);

        // [THEN] Bal. Account Type = "Bank Account" in Payment Line
        GenJournalLine.TestField("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
    end;

    local procedure PrepareGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Option; AccountType: Option; PostedDocType: Option; var PostedDocNo: Code[20]; Sign: Integer)
    begin
        PostedDocNo :=
          CreateAndPostGenJournalLine(PostedDocType, AccountType, CreateAccountNo(AccountType), Sign);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, DocumentType, AccountType, '', 0);
    end;

    local procedure CreateAndPostGenJournalLine(DocumentType: Option; AccountType: Option; AccountNo: Code[20]; Sign: Integer): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, DocumentType, AccountType, AccountNo, Sign * LibraryRandom.RandDecInRange(1000, 2000, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreatePaymentLineWithAccountTypeAndBalAccountType(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Integer; BalAccountType: Integer)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, AccountType, '', 0);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAccountNo(AccountType: Option): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        case AccountType of
            GenJournalLine."Account Type"::Customer:
                exit(LibrarySales.CreateCustomerNo);
            GenJournalLine."Account Type"::Vendor:
                exit(LibraryPurchase.CreateVendorNo);
            GenJournalLine."Account Type"::Employee:
                exit(LibraryHumanResource.CreateEmployeeNoWithBankAccount);
        end;
    end;

    local procedure MockCustLedgerEntryWithDocNo(DocNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Init;
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Document No." := DocNo;
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesSelectDocModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", LibraryVariableStorage.DequeueInteger);
        CustLedgerEntry.SetRange("Document No.", LibraryVariableStorage.DequeueText);
        CustLedgerEntry.FindFirst;
        ApplyCustomerEntries.GotoRecord(CustLedgerEntry);
        ApplyCustomerEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesSelectDocModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document Type", LibraryVariableStorage.DequeueInteger);
        VendorLedgerEntry.SetRange("Document No.", LibraryVariableStorage.DequeueText);
        VendorLedgerEntry.FindFirst;
        ApplyVendorEntries.GotoRecord(VendorLedgerEntry);
        ApplyVendorEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyEmployeeEntriesSelectDocModalPageHandler(var ApplyEmployeeEntries: TestPage "Apply Employee Entries")
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.SetRange("Document Type", LibraryVariableStorage.DequeueInteger);
        EmployeeLedgerEntry.SetRange("Document No.", LibraryVariableStorage.DequeueText);
        EmployeeLedgerEntry.FindFirst;
        ApplyEmployeeEntries.GotoRecord(EmployeeLedgerEntry);
        ApplyEmployeeEntries.OK.Invoke;
    end;
}

