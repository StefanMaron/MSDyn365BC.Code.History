codeunit 144000 Banks
{
    // Test Cases for Banks
    // 1. Check if the system allows creating a new Payment Order.
    // 2. Test that execution of report "Suggest Payments" suggest payments from Posted Purchase Invoice and create Payment Order Lines
    // 3. Test issuing Payment Order and create Issued Payment Order
    // 4. Test copying Payment Order to Bank Statement
    // 5. Test applying Bank Statement with Payment Order and creating Payment Reconciliation Journal that corresponds to the Payment Order
    // 6. Test applying bank statement with Sales Invoice and creating Payment Reconciliation Journal that corresponds to the Sales Invoice
    // 7. Test that invalid bank account no. will cause error during the issuing
    // 8. Test suggests that payment of the invoice within two Payment Orders
    // 9. Check that correct Amount is present on Payment Order Report after issuing Payment Order.

    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit Assert;
        LibraryBank: Codeunit "Library - Bank";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        SuggestPaymentsErr: Label 'Payment Order Line was not created.';
        CopyingPayOrderErr: Label 'Bank Statement Line was not created.';
        IssueBankStatementQst: Label '&Issue,Issue and &create payment reconciliation journal';
        ApplyingBankStatementErr: Label 'Bank Reconciliation Line was not created.';
        InvalidFormatBankAccountErr: Label '''Account No.'' %1 in ''Payment Order Line: %2,%3 is malformed.', Comment = '%1=Account No.; %2=Payment Order No.; %3=Line No.';
        BlockingEntriesErr: Label 'Payment Order Line was created.';
        RowNotFoundErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2.', Comment = '%1=Field Caption,%2=Field Value;';
        ApplyingErr: Label 'Applying error.';

    local procedure Initialize()
    begin
        LibraryRandom.SetSeed(1);  // Use Random Number Generator to generate the seed for RANDOM function.
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        UpdateBankAccount;

        isInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentOrderCreation()
    var
        PmtOrdHdr: Record "Payment Order Header";
        PmtOrdLn: Record "Payment Order Line";
    begin
        // Check if the system allows creating a new Payment Order.

        // 1.Setup:
        Initialize;

        // 2.Exercise: Create Payment Order
        CreatePaymentOrder(PmtOrdHdr, PmtOrdLn);

        // 3.Verify: Verify of creating Payment Order Header and Payment Order Line
        PmtOrdHdr.Get(PmtOrdHdr."No.");
        PmtOrdLn.Get(PmtOrdLn."Payment Order No.", PmtOrdLn."Line No.");
    end;

    [HandlerFunctions('SuggestPaymentsHandler')]
    [Scope('OnPrem')]
    procedure PaymentsSuggestionFromPostedPurchInvoice()
    var
        PmtOrdHdr: Record "Payment Order Header";
        PmtOrdLn: Record "Payment Order Line";
        PurchHdr: Record "Purchase Header";
        PurchLn: Record "Purchase Line";
    begin
        // Tests that execution of report "Suggest Payments" suggest payments from Posted Purchase Invoice
        // and create Payment Order Lines

        // 1.Setup:
        Initialize;

        // Create Purchase Invoice for payments suggestion
        CreatePurchaseInvoice(PurchHdr, PurchLn);
        PostPurchaseDocument(PurchHdr);

        // 2.Exercise: Create Payment Order with lines of suggested from Purchase Invoice
        CreatePaymentOrderFromPurchaseInvoice(PmtOrdHdr, PurchHdr);

        // 3.Verify: Verify of creating Payment Order Line that corresponds to the Purchase Invoice
        PmtOrdLn.Reset();
        PmtOrdLn.SetRange("Payment Order No.", PmtOrdHdr."No.");
        PmtOrdLn.SetRange(Type, PmtOrdLn.Type::Vendor);
        PmtOrdLn.SetRange("No.", PurchHdr."Buy-from Vendor No.");
        PmtOrdLn.SetRange("Cust./Vendor Bank Account Code", PurchHdr."Bank Account Code");
        PmtOrdLn.SetRange("Account No.", PurchHdr."Bank Account No.");
        PmtOrdLn.SetRange("Amount(Pay.Order Curr.) to Pay", PurchLn.Amount);
        Assert.IsTrue(PmtOrdLn.FindFirst, SuggestPaymentsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckIssuePaymentOrder()
    var
        PmtOrdHdr: Record "Payment Order Header";
        PmtOrdLn: Record "Payment Order Line";
        IssuedPmtOrdHdr: Record "Issued Payment Order Header";
        IssuedPmtOrdLn: Record "Issued Payment Order Line";
    begin
        // Test issuing Payment Order and create Issued Payment Order

        // 1.Setup:
        Initialize;

        // Create Payment Order with lines
        CreatePaymentOrder(PmtOrdHdr, PmtOrdLn);

        // 2.Exercise: Execute process of issuing and creating Issued Payment Order Header and Issued Payment Order Line
        IssuePaymentOrder(PmtOrdHdr);

        // 3.Verify: Verify of creating Issued Payment Order Header and Issued Payment Order Line
        IssuedPmtOrdHdr.Get(PmtOrdHdr."Last Issuing No.");
        IssuedPmtOrdLn.Get(IssuedPmtOrdHdr."No.", PmtOrdLn."Line No.");
    end;

    [Test]
    [HandlerFunctions('CopyPaymentOrderHandler')]
    [Scope('OnPrem')]
    procedure CopyingPaymentOrderToBankStatement()
    var
        BankStmtHdr: Record "Bank Statement Header";
        BankStmtLn: Record "Bank Statement Line";
        PmtOrdHdr: Record "Payment Order Header";
        PmtOrdLn: Record "Payment Order Line";
    begin
        // Test copying Payment Order to Bank Statement

        // 1.Setup:
        Initialize;

        // Create Payment Order with lines
        CreatePaymentOrder(PmtOrdHdr, PmtOrdLn);
        // Execute process of issuing and creating Issued Payment Order Header and Issued Payment Order Line
        IssuePaymentOrder(PmtOrdHdr);

        // 2.Exercise: Create Bank Statement with lines of copied from Payment Order
        CreateBankStatementFromPaymentOrder(BankStmtHdr, PmtOrdHdr);

        // 3.Verify: Verify of creating Bank Statement Line that corresponds to the Payment Order Line
        BankStmtLn.Reset();
        BankStmtLn.SetRange("Bank Statement No.", BankStmtHdr."No.");
        BankStmtLn.SetRange("Account No.", PmtOrdLn."Account No.");
        BankStmtLn.SetRange("Variable Symbol", PmtOrdLn."Variable Symbol");
        BankStmtLn.SetRange(Amount, -PmtOrdLn."Amount to Pay");
        Assert.IsTrue(BankStmtLn.FindFirst, CopyingPayOrderErr);
    end;

    [Test]
    [HandlerFunctions('ReportBankStatementHandler,StrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyingBankStatementWithSalesInvoice()
    var
        BankStmtHdr: Record "Bank Statement Header";
        BankStmtLn: Record "Bank Statement Line";
        BankAccReconLn: Record "Bank Acc. Reconciliation Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        SalesHdr: Record "Sales Header";
        SalesLn: Record "Sales Line";
        PostDocNo: Code[20];
    begin
        // Test applying bank statement with Sales Invoice and creating
        // Payment Reconciliation Journal that corresponds to the Sales Invoice

        // 1.Setup:
        Initialize;

        // Create Sales Invoice
        CreateSalesInvoice(SalesHdr, SalesLn);

        // Post Purchase Invoice
        PostDocNo := PostSalesDocument(SalesHdr);
        CustLedgEntry.FindLast;
        CustLedgEntry.CalcFields(Amount);

        // Create Bank Statement
        LibraryBank.CreateBankStatementHeader(BankStmtHdr);
        LibraryBank.CreateBankStatementLine(BankStmtLn, BankStmtHdr, 0, '', CustLedgEntry.Amount);
        BankStmtLn.Validate("Variable Symbol", SalesHdr."Variable Symbol");
        BankStmtLn.Modify(true);

        // 2.Exercise: Execute process of issuing and creating Gen. Journal Lines
        IssueBankStatementAndPrint(BankStmtHdr);

        // 3.Verify: Verify of creating Gen. Journal Lines that corresponds to the Sales Invoice
        BankAccReconLn.Reset();
        BankAccReconLn.SetRange("Statement Type", BankAccReconLn."Statement Type"::"Payment Application");
        BankAccReconLn.SetRange("Bank Account No.", BankStmtHdr."Bank Account No.");
        BankAccReconLn.SetRange("Statement No.", BankStmtHdr."Last Issuing No.");
        BankAccReconLn.SetRange("Account Type", BankAccReconLn."Account Type"::Customer);
        BankAccReconLn.SetRange("Account No.", CustLedgEntry."Customer No.");
        BankAccReconLn.SetRange("Statement Amount", CustLedgEntry.Amount);
        Assert.IsTrue(BankAccReconLn.FindFirst, ApplyingBankStatementErr);
        Assert.IsTrue(BankAccReconLn.GetAppliedToDocumentNo = PostDocNo, ApplyingErr);
        Assert.IsTrue(BankAccReconLn.GetAppliedToEntryNo = Format(CustLedgEntry."Entry No."), ApplyingErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ErrorMessagesHandler')]
    [Scope('OnPrem')]
    procedure InvalidFormatBankAccountNoDuringIssuing()
    var
        PmtOrdHdr: Record "Payment Order Header";
        PmtOrdLn: Record "Payment Order Line";
    begin
        // Test that invalid bank account no. will cause error during the issuing

        // 1.Setup:
        Initialize;

        // Create Payment Order with invalid bank account no.
        CreatePaymentOrder(PmtOrdHdr, PmtOrdLn);
        PmtOrdLn."Account No." := LibraryBank.GetInvalidBankAccountNo;
        PmtOrdLn.Modify(true);

        // 2.Exercise: Execute process of issuing
        asserterror IssuePaymentOrder(PmtOrdHdr);

        // 3.Verify: Verify expected error in error message handler
        Assert.ExpectedError(
          StrSubstNo(InvalidFormatBankAccountErr, PmtOrdLn."Account No.", PmtOrdLn."Payment Order No.", PmtOrdLn."Line No."));
    end;

    [Test]
    [HandlerFunctions('SuggestPaymentsHandler')]
    [Scope('OnPrem')]
    procedure BlockingEntriesToPaymentOrder()
    var
        PmtOrdHdr: Record "Payment Order Header";
        PmtOrdHdr2: Record "Payment Order Header";
        PmtOrdLn: Record "Payment Order Line";
        PurchHdr: Record "Purchase Header";
        PurchLn: Record "Purchase Line";
    begin
        // Test suggests that payment of the invoice within two Payment Orders

        // 1.Setup:
        Initialize;

        // Create Purchase Invoice for payments suggestion
        CreatePurchaseInvoice(PurchHdr, PurchLn);
        PostPurchaseDocument(PurchHdr);

        // Create Payment Order from Purchase Invoice
        CreatePaymentOrderFromPurchaseInvoice(PmtOrdHdr, PurchHdr);

        // 2.Exercise: Create Payment Order from Purchase Invoice but do not created lines
        CreatePaymentOrderFromPurchaseInvoice(PmtOrdHdr2, PurchHdr);

        // 3.Verify: Verify that was not created Payment Line
        PmtOrdLn.Reset();
        PmtOrdLn.SetRange("Payment Order No.", PmtOrdHdr2."No.");
        Assert.IsTrue(PmtOrdLn.IsEmpty, BlockingEntriesErr);
    end;

    [Test]
    [HandlerFunctions('RequestPagePaymentOrderHandler')]
    [Scope('OnPrem')]
    procedure PrintingIssuedPaymentOrder()
    var
        PmtOrdHdr: Record "Payment Order Header";
        PmtOrdLn: Record "Payment Order Line";
        IssuedPmtOrdHdr: Record "Issued Payment Order Header";
    begin
        // 1.Setup:
        Initialize;

        // Create Payment Order
        CreatePaymentOrder(PmtOrdHdr, PmtOrdLn);
        IssuePaymentOrder(PmtOrdHdr);
        IssuedPmtOrdHdr.Get(PmtOrdHdr."Last Issuing No.");

        // 2.Exercise: Print Payment Order
        PrintPaymentOrderDomestics(IssuedPmtOrdHdr);

        // 3.Verify:
        IssuedPmtOrdHdr.CalcFields(Amount);

        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('Issued_Payment_Order_Header__No__', IssuedPmtOrdHdr."No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'Issued_Payment_Order_Header__No__', IssuedPmtOrdHdr."No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('Issued_Payment_Order_Header__Amount', IssuedPmtOrdHdr.Amount);
    end;

    local procedure CreatePaymentOrder(var PmtOrdHdr: Record "Payment Order Header"; var PmtOrdLn: Record "Payment Order Line")
    var
        BankAcc: Record "Bank Account";
    begin
        LibraryBank.CreatePaymentOrderHeader(PmtOrdHdr);
        LibraryBank.FindBankAccount(BankAcc);
        LibraryBank.CreatePaymentOrderLine(
          PmtOrdLn, PmtOrdHdr, PmtOrdLn.Type::"Bank Account", BankAcc."No.", LibraryRandom.RandInt(1000))
    end;

    local procedure CreatePaymentOrderFromPurchaseInvoice(var PmtOrdHdr: Record "Payment Order Header"; PurchHdr: Record "Purchase Header")
    begin
        // Create payment order header
        LibraryBank.CreatePaymentOrderHeader(PmtOrdHdr);
        PmtOrdHdr.Validate("Payment Order Currency Code", PurchHdr."Currency Code");
        PmtOrdHdr.Modify();

        // Create payment order lines from purchase invoice
        DefaultSuggestPayments(PmtOrdHdr);
    end;

    local procedure CreateBankStatementFromPaymentOrder(var BankStmtHdr: Record "Bank Statement Header"; PmtOrdHdr: Record "Payment Order Header")
    var
        ReqPageParams: array[10] of Variant;
    begin
        // Create bank statement header
        LibraryBank.CreateBankStatementHeader(BankStmtHdr);

        // Create bank statement lines from payment order
        ReqPageParams[1] := PmtOrdHdr."Last Issuing No."; // Document No.
        CopyPaymentOrder(BankStmtHdr, ReqPageParams);
    end;

    local procedure CreatePurchaseInvoice(var PurchHdr: Record "Purchase Header"; var PurchLn: Record "Purchase Line")
    var
        Vend: Record Vendor;
        VendBankAcc: Record "Vendor Bank Account";
    begin
        FindVendor(Vend);
        CreateVendorBankAccount(VendBankAcc, Vend);

        LibraryPurchase.CreatePurchHeader(PurchHdr, PurchHdr."Document Type"::Invoice, Vend."No.");
        PurchHdr.Validate("Vendor Invoice No.", PurchHdr."No.");
        PurchHdr.Validate("Vendor Cr. Memo No.", PurchHdr."No.");
        PurchHdr.Validate("Due Date", WorkDate);
        PurchHdr.Validate("Bank Account Code", VendBankAcc.Code);
        PurchHdr.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchLn, PurchHdr, PurchLn.Type::"G/L Account", GetGLAccountNo, 1);
        PurchLn.Validate("Direct Unit Cost", LibraryRandom.RandInt(1000));
        PurchLn.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line")
    begin
        LibrarySales.CreateSalesHeader(SalesHdr, SalesHdr."Document Type"::Invoice, '');
        SalesHdr.Validate("Variable Symbol", LibraryBank.GenerateVariableSymbol);
        SalesHdr.Modify(true);

        LibrarySales.CreateSalesLine(SalesLn, SalesHdr, SalesLn.Type::"G/L Account", GetGLAccountNo, 1);
        SalesLn.Validate("Unit Price", LibraryRandom.RandInt(1000));
        SalesLn.Modify(true);
    end;

    local procedure CreateVendorBankAccount(var VendBankAcc: Record "Vendor Bank Account"; Vend: Record Vendor)
    begin
        LibraryPurchase.CreateVendorBankAccount(VendBankAcc, Vend."No.");
        VendBankAcc.Validate("Bank Account No.", LibraryBank.GetBankAccountNo);
        VendBankAcc.Modify();
    end;

    local procedure FindVendor(var Vendor: Record Vendor)
    begin
        Vendor.SetFilter("Vendor Posting Group", '<>''''');
        Vendor.SetFilter("Gen. Bus. Posting Group", '<>''''');
        Vendor.SetRange(Blocked, Vendor.Blocked::" ");
        Vendor.FindFirst;
    end;

    local procedure FindGLAccount(var GLAccount: Record "G/L Account")
    begin
        LibraryERM.FindGLAccount(GLAccount);
    end;

    local procedure GetGLAccountNo(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        FindGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure PostPurchaseDocument(var PurchHdr: Record "Purchase Header"): Code[20]
    begin
        exit(LibraryPurchase.PostPurchaseDocument(PurchHdr, true, true));
    end;

    local procedure PostSalesDocument(var SalesHdr: Record "Sales Header"): Code[20]
    begin
        exit(LibrarySales.PostSalesDocument(SalesHdr, true, true));
    end;

    local procedure PrintPaymentOrderDomestics(var IssuedPmtOrdHdr: Record "Issued Payment Order Header")
    begin
        Commit();
        IssuedPmtOrdHdr.SetRecFilter;
        LibraryBank.PrintPaymentOrderDomestic(IssuedPmtOrdHdr, true);
    end;

    local procedure IssuePaymentOrder(var PmtOrdHdr: Record "Payment Order Header")
    begin
        LibraryBank.IssuePaymentOrder(PmtOrdHdr);
    end;

    local procedure IssueBankStatementAndPrint(var BankStmtHdr: Record "Bank Statement Header")
    begin
        LibraryBank.IssueBankStatementAndPrint(BankStmtHdr);
    end;

    local procedure DefaultSuggestPayments(PmtOrdHdr: Record "Payment Order Header")
    var
        ReqPageParams: array[10] of Variant;
    begin
        ReqPageParams[1] := LibraryRandom.RandDate(1);  // Last Payment Date  (Date must be greater than WORKDATE)
        ReqPageParams[2] := 2;                                  // Vendor Payables    (2 - "Only Payables")
        ReqPageParams[3] := 4;                                  // Customer Payables  (4 - "Only No Suggest")
        ReqPageParams[4] := 2;                                  // Keep Currency      (2 - "Payment Order")
        ReqPageParams[5] := true;                               // Only Entries in Currency

        SuggestPayments(PmtOrdHdr, ReqPageParams);
    end;

    local procedure SuggestPayments(PmtOrdHdr: Record "Payment Order Header"; ReqPageParams: array[10] of Variant)
    begin
        // Initialize paramaters for request page handler
        LibraryVariableStorage.Enqueue(ReqPageParams[1]);
        LibraryVariableStorage.Enqueue(ReqPageParams[2]);
        LibraryVariableStorage.Enqueue(ReqPageParams[3]);
        LibraryVariableStorage.Enqueue(ReqPageParams[4]);
        LibraryVariableStorage.Enqueue(ReqPageParams[5]);

        LibraryBank.SuggestPayments(PmtOrdHdr);
    end;

    local procedure CopyPaymentOrder(var BankStmtHdr: Record "Bank Statement Header"; ReqPageParams: array[10] of Variant)
    begin
        // Initialize paramaters for request page handler
        LibraryVariableStorage.Enqueue(ReqPageParams[1]);

        LibraryBank.CopyPaymentOrder(BankStmtHdr);
    end;

    local procedure UpdateBankAccount()
    var
        BankAcc: Record "Bank Account";
        BaseCalendar: Record "Base Calendar";
        BankPmtApplRuleCode: Record "Bank Pmt. Appl. Rule Code";
        TextToAccMappingCode: Record "Text-to-Account Mapping Code";
    begin
        LibraryBank.FindBankAccount(BankAcc);
        LibraryBank.FindBaseCalendar(BaseCalendar);
        LibraryBank.CreateAccountMappingCode(TextToAccMappingCode);
        LibraryBank.CreateBankPmtApplRuleCode(BankPmtApplRuleCode);

        // Change bank account no. to czech format
        BankAcc.Validate("Bank Account No.", LibraryBank.GetBankAccountNo);
        BankAcc.Validate("Non Associated Payment Account", GetGLAccountNo);
        BankAcc.Validate("Check Czech Format on Issue", true);
        BankAcc.Validate("Base Calendar Code", BaseCalendar.Code);
        BankAcc.Validate("Domestic Payment Order", REPORT::"Payment Order");
        BankAcc.Validate("Post Per Line", true);
        BankAcc.Validate("Variable S. to Variable S.", true);
        BankAcc.Validate("Payment Order Nos.", LibraryERM.CreateNoSeriesCode);
        BankAcc.Validate("Issued Payment Order Nos.", LibraryERM.CreateNoSeriesCode);
        BankAcc.Validate("Bank Statement Nos.", LibraryERM.CreateNoSeriesCode);
        BankAcc.Validate("Issued Bank Statement Nos.", LibraryERM.CreateNoSeriesCode);
        BankAcc.Validate("Bank Pmt. Appl. Rule Code", BankPmtApplRuleCode.Code);
        BankAcc.Validate("Text-to-Account Mapping Code", TextToAccMappingCode.Code);
        BankAcc.Modify(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestPaymentsHandler(var SuggestPaymentsReqPage: TestRequestPage "Suggest Payments")
    var
        FieldValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldValue);
        SuggestPaymentsReqPage.LastDueDateToPayReq.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        SuggestPaymentsReqPage.TypeVendor.SetValue(SuggestPaymentsReqPage.TypeCustomer.GetOption(FieldValue));
        LibraryVariableStorage.Dequeue(FieldValue);
        SuggestPaymentsReqPage.TypeCustomer.SetValue(SuggestPaymentsReqPage.TypeCustomer.GetOption(FieldValue));
        LibraryVariableStorage.Dequeue(FieldValue);
        SuggestPaymentsReqPage.Currency.SetValue(SuggestPaymentsReqPage.Currency.GetOption(FieldValue));
        LibraryVariableStorage.Dequeue(FieldValue);
        SuggestPaymentsReqPage.KeepCurrency.SetValue(FieldValue);
        SuggestPaymentsReqPage.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyPaymentOrderHandler(var CopyPaymentOrderReqPage: TestRequestPage "Copy Payment Order")
    var
        FieldValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldValue);
        CopyPaymentOrderReqPage.DocNo.SetValue(FieldValue);
        CopyPaymentOrderReqPage.OK.Invoke;
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure ReportBankStatementHandler(var BankStatement: Report "Bank Statement")
    begin
        exit;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPagePaymentOrderHandler(var PaymentOrder: TestRequestPage "Payment Order")
    begin
        PaymentOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ErrorMessagesHandler(var ErrorMessages: TestPage "Error Messages")
    begin
        Error(ErrorMessages.Description.Value);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        case Options of
            IssueBankStatementQst:
                Choice := 2;
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        exit;
    end;
}

