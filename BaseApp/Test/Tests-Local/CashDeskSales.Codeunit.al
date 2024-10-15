codeunit 144101 "Cash Desk Sales"
{
    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        LibraryCashDesk: Codeunit "Library - Cash Desk";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryRandom.SetSeed(1);  // Use Random Number Generator to generate the seed for RANDOM function.
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        isInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatingReceiptCashDocumentFromSalesInvoice()
    begin
        ReceiptCashDocumentFromSalesInvoice(1); // Create
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasingReceiptCashDocumentFromSalesInvoice()
    begin
        ReceiptCashDocumentFromSalesInvoice(2); // Release
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingReceiptCashDocumentFromSalesInvoice()
    begin
        ReceiptCashDocumentFromSalesInvoice(3); // Post
    end;

    local procedure ReceiptCashDocumentFromSalesInvoice(CashDocumentStatus: Option)
    var
        BankAcc: Record "Bank Account";
        CashDocHdr: Record "Cash Document Header";
        CashDocLn: Record "Cash Document Line";
        PaymentMethod: Record "Payment Method";
        SalesInvHdr: Record "Sales Invoice Header";
        SalesHdr: Record "Sales Header";
        SalesLn: Record "Sales Line";
        PostedCashDocHdr: Record "Posted Cash Document Header";
        PostedCashDocLn: Record "Posted Cash Document Line";
        PostDocNo: Code[20];
    begin
        // 1.Setup
        Initialize;

        CreateCashDesk(BankAcc);
        CreatePaymentMethod(PaymentMethod, BankAcc."No.", CashDocumentStatus);
        CreateSalesInvoice(SalesHdr, SalesLn);
        ModifyPaymentMethodInSalesDocument(SalesHdr, PaymentMethod);

        // 2. Exercise
        PostDocNo := PostSalesDocument(SalesHdr);

        // 3. Verify
        SalesInvHdr.Get(PostDocNo);
        SalesInvHdr.CalcFields("Amount Including VAT");

        case CashDocumentStatus of
            PaymentMethod."Cash Document Status"::Create,
            PaymentMethod."Cash Document Status"::Release:
                begin
                    CashDocHdr.SetRange("Cash Desk No.", BankAcc."No.");
                    CashDocHdr.SetRange("Cash Document Type", CashDocHdr."Cash Document Type"::Receipt);
                    if CashDocumentStatus = PaymentMethod."Cash Document Status"::Create then
                        CashDocHdr.SetRange(Status, CashDocHdr.Status::Open)
                    else
                        CashDocHdr.SetRange(Status, CashDocHdr.Status::Released);
                    CashDocHdr.SetRange("Posting Date", SalesInvHdr."Posting Date");
                    CashDocHdr.FindLast;

                    CashDocLn.SetRange("Cash Desk No.", CashDocHdr."Cash Desk No.");
                    CashDocLn.SetRange("Cash Document No.", CashDocHdr."No.");
                    CashDocLn.FindFirst;

                    CashDocLn.TestField("Account Type", CashDocLn."Account Type"::Customer);
                    CashDocLn.TestField("Account No.", SalesInvHdr."Bill-to Customer No.");
                    CashDocLn.TestField(Amount, SalesInvHdr."Amount Including VAT");
                    CashDocLn.TestField("Applies-To Doc. Type", CashDocLn."Applies-To Doc. Type"::Invoice);
                    CashDocLn.TestField("Applies-To Doc. No.", SalesInvHdr."No.");
                end;
            PaymentMethod."Cash Document Status"::Post:
                begin
                    PostedCashDocHdr.SetRange("Cash Desk No.", BankAcc."No.");
                    PostedCashDocHdr.SetRange("Cash Document Type", PostedCashDocHdr."Cash Document Type"::Receipt);
                    PostedCashDocHdr.SetRange("Posting Date", SalesInvHdr."Posting Date");
                    PostedCashDocHdr.FindLast;

                    PostedCashDocLn.SetRange("Cash Desk No.", PostedCashDocHdr."Cash Desk No.");
                    PostedCashDocLn.SetRange("Cash Document No.", PostedCashDocHdr."No.");
                    PostedCashDocLn.FindFirst;

                    PostedCashDocLn.TestField("Account Type", PostedCashDocLn."Account Type"::Customer);
                    PostedCashDocLn.TestField("Account No.", SalesInvHdr."Bill-to Customer No.");
                    PostedCashDocLn.TestField(Amount, SalesInvHdr."Amount Including VAT");
                    PostedCashDocLn.TestField("Applies-To Doc. Type", PostedCashDocLn."Applies-To Doc. Type"::Invoice);
                    PostedCashDocLn.TestField("Applies-To Doc. No.", SalesInvHdr."No.");
                end;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatingWithdrawalCashDocumentFromSalesCrMemo()
    begin
        WithdrawalCashDocumentFromSalesCrMemo(1); // Create
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasingWithdrawalCashDocumentFromSalesCrMemo()
    begin
        WithdrawalCashDocumentFromSalesCrMemo(2); // Release
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingWithdrawalCashDocumentFromSalesCrMemo()
    begin
        WithdrawalCashDocumentFromSalesCrMemo(3); // Post
    end;

    local procedure WithdrawalCashDocumentFromSalesCrMemo(CashDocumentStatus: Option)
    var
        BankAcc: Record "Bank Account";
        CashDocHdr: Record "Cash Document Header";
        CashDocLn: Record "Cash Document Line";
        PaymentMethod: Record "Payment Method";
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        SalesHdr: Record "Sales Header";
        SalesLn: Record "Sales Line";
        PostedCashDocHdr: Record "Posted Cash Document Header";
        PostedCashDocLn: Record "Posted Cash Document Line";
        PostDocNo: Code[20];
    begin
        // 1.Setup
        Initialize;

        CreateCashDesk(BankAcc);
        CreatePaymentMethod(PaymentMethod, BankAcc."No.", CashDocumentStatus);
        CreateSalesCreditMemo(SalesHdr, SalesLn);
        ModifyPaymentMethodInSalesDocument(SalesHdr, PaymentMethod);

        // 2. Exercise
        PostDocNo := PostSalesDocument(SalesHdr);

        // 3. Verify
        SalesCrMemoHdr.Get(PostDocNo);
        SalesCrMemoHdr.CalcFields("Amount Including VAT");

        case CashDocumentStatus of
            PaymentMethod."Cash Document Status"::Create,
            PaymentMethod."Cash Document Status"::Release:
                begin
                    CashDocHdr.SetRange("Cash Desk No.", BankAcc."No.");
                    CashDocHdr.SetRange("Cash Document Type", CashDocHdr."Cash Document Type"::Withdrawal);
                    if CashDocumentStatus = PaymentMethod."Cash Document Status"::Create then
                        CashDocHdr.SetRange(Status, CashDocHdr.Status::Open)
                    else
                        CashDocHdr.SetRange(Status, CashDocHdr.Status::Released);
                    CashDocHdr.SetRange("Posting Date", SalesCrMemoHdr."Posting Date");
                    CashDocHdr.FindLast;

                    CashDocLn.SetRange("Cash Desk No.", CashDocHdr."Cash Desk No.");
                    CashDocLn.SetRange("Cash Document No.", CashDocHdr."No.");
                    CashDocLn.FindFirst;

                    CashDocLn.TestField("Account Type", CashDocLn."Account Type"::Customer);
                    CashDocLn.TestField("Account No.", SalesCrMemoHdr."Bill-to Customer No.");
                    CashDocLn.TestField(Amount, SalesCrMemoHdr."Amount Including VAT");
                    CashDocLn.TestField("Applies-To Doc. Type", CashDocLn."Applies-To Doc. Type"::"Credit Memo");
                    CashDocLn.TestField("Applies-To Doc. No.", SalesCrMemoHdr."No.");
                end;
            PaymentMethod."Cash Document Status"::Post:
                begin
                    PostedCashDocHdr.SetRange("Cash Desk No.", BankAcc."No.");
                    PostedCashDocHdr.SetRange("Cash Document Type", PostedCashDocHdr."Cash Document Type"::Withdrawal);
                    PostedCashDocHdr.SetRange("Posting Date", SalesCrMemoHdr."Posting Date");
                    PostedCashDocHdr.FindLast;

                    PostedCashDocLn.SetRange("Cash Desk No.", PostedCashDocHdr."Cash Desk No.");
                    PostedCashDocLn.SetRange("Cash Document No.", PostedCashDocHdr."No.");
                    PostedCashDocLn.FindFirst;

                    PostedCashDocLn.TestField("Account Type", PostedCashDocLn."Account Type"::Customer);
                    PostedCashDocLn.TestField("Account No.", SalesCrMemoHdr."Bill-to Customer No.");
                    PostedCashDocLn.TestField(Amount, SalesCrMemoHdr."Amount Including VAT");
                    PostedCashDocLn.TestField("Applies-To Doc. Type", PostedCashDocLn."Applies-To Doc. Type"::"Credit Memo");
                    PostedCashDocLn.TestField("Applies-To Doc. No.", SalesCrMemoHdr."No.");
                end;
        end;
    end;

    local procedure CreateBankAccountPostingGroup(var BankAccPostingGroup: Record "Bank Account Posting Group"; GLAccountNo: Code[20])
    begin
        LibraryERM.CreateBankAccountPostingGroup(BankAccPostingGroup);
        BankAccPostingGroup."G/L Account No." := GLAccountNo;
        BankAccPostingGroup.Modify(true);
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
        BankAcc."Bank Acc. Posting Group" := BankAccPostingGroupCode;
        BankAcc."Debit Rounding Account" := GetNewGLAccountNo(false);
        BankAcc."Credit Rounding Account" := GetNewGLAccountNo(false);
        BankAcc."Rounding Method Code" := RoundingMethodCode;
        BankAcc."Cash Receipt Limit" := 10000;
        BankAcc."Cash Withdrawal Limit" := 10000;
        BankAcc."Max. Balance" := 10000;
        BankAcc."Min. Balance" := 10000;
        BankAcc."Cash Document Receipt Nos." := LibraryUtility.GetGlobalNoSeriesCode;
        BankAcc."Cash Document Withdrawal Nos." := LibraryUtility.GetGlobalNoSeriesCode;
        BankAcc.Modify(true);
    end;

    local procedure CreateCashDeskUser(var CashDeskUser: Record "Cash Desk User"; CashDeskNo: Code[20])
    begin
        LibraryCashDesk.CreateCashDeskUser(CashDeskUser, CashDeskNo, true, true, true);
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

    local procedure CreatePaymentMethod(var PaymentMethod: Record "Payment Method"; CashDeskCode: Code[20]; CashDocumentStatus: Option)
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod."Cash Desk Code" := CashDeskCode;
        PaymentMethod."Cash Document Status" := CashDocumentStatus;
        PaymentMethod.Modify();
    end;

    local procedure CreateSalesDocument(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line"; DocumentType: Option; UnitPrice: Decimal)
    var
        Cust: Record Customer;
    begin
        LibrarySales.CreateCustomer(Cust);
        LibrarySales.CreateSalesHeader(SalesHdr, DocumentType, Cust."No.");
        LibrarySales.CreateSalesLine(
          SalesLn, SalesHdr, SalesLn.Type::"G/L Account", GetNewGLAccountNo(true), 1);
        SalesLn.Validate("Unit Price", UnitPrice);
        SalesLn.Modify(true);
    end;

    local procedure CreateSalesCreditMemo(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line")
    begin
        CreateSalesDocument(SalesHdr, SalesLn, SalesHdr."Document Type"::"Credit Memo", LibraryRandom.RandDec(10000, 2));
    end;

    local procedure CreateSalesInvoice(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line")
    begin
        CreateSalesDocument(SalesHdr, SalesLn, SalesHdr."Document Type"::Invoice, LibraryRandom.RandDec(10000, 2));
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

    local procedure GetNewGLAccountNo(WithVATPostingSetup: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        CreateGLAccount(GLAccount, WithVATPostingSetup);
        exit(GLAccount."No.");
    end;

    local procedure ModifyPaymentMethodInSalesDocument(var SalesHdr: Record "Sales Header"; PaymentMethod: Record "Payment Method")
    begin
        SalesHdr.Validate("Payment Method Code", PaymentMethod.Code);
        SalesHdr.Modify();
    end;

    local procedure PostSalesDocument(var SalesHdr: Record "Sales Header"): Code[20]
    begin
        exit(LibrarySales.PostSalesDocument(SalesHdr, true, true));
    end;
}

