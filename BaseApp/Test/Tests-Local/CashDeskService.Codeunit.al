codeunit 144103 "Cash Desk Service"
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
        LibraryService: Codeunit "Library - Service";
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
    procedure CreatingReceiptCashDocumentFromPurchaseInvoice()
    begin
        ReceiptCashDocumentFromPurchaseInvoice(1); // Create
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasingReceiptCashDocumentFromPurchaseInvoice()
    begin
        ReceiptCashDocumentFromPurchaseInvoice(2); // Release
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingReceiptCashDocumentFromPurchaseInvoice()
    begin
        ReceiptCashDocumentFromPurchaseInvoice(3); // Post
    end;

    local procedure ReceiptCashDocumentFromPurchaseInvoice(CashDocumentStatus: Option)
    var
        BankAcc: Record "Bank Account";
        CashDocHdr: Record "Cash Document Header";
        CashDocLn: Record "Cash Document Line";
        PaymentMethod: Record "Payment Method";
        ServInvHdr: Record "Service Invoice Header";
        ServHdr: Record "Service Header";
        ServLn: Record "Service Line";
        PostedCashDocHdr: Record "Posted Cash Document Header";
        PostedCashDocLn: Record "Posted Cash Document Line";
        PostDocNo: Code[20];
    begin
        // 1.Setup
        Initialize;

        CreateCashDesk(BankAcc);
        CreatePaymentMethod(PaymentMethod, BankAcc."No.", CashDocumentStatus);
        CreateServiceInvoice(ServHdr, ServLn);
        ModifyPaymentMethodInServiceDocument(ServHdr, PaymentMethod);

        // 2. Exercise
        PostDocNo := PostServiceDocument(ServHdr);

        // 3. Verify
        ServInvHdr.Get(PostDocNo);

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
                    CashDocHdr.SetRange("Posting Date", ServInvHdr."Posting Date");
                    CashDocHdr.FindLast;

                    CashDocLn.SetRange("Cash Desk No.", CashDocHdr."Cash Desk No.");
                    CashDocLn.SetRange("Cash Document No.", CashDocHdr."No.");
                    CashDocLn.FindFirst;

                    CashDocLn.TestField("Account Type", CashDocLn."Account Type"::Customer);
                    CashDocLn.TestField("Account No.", ServInvHdr."Bill-to Customer No.");
                    CashDocLn.TestField("Applies-To Doc. Type", CashDocLn."Applies-To Doc. Type"::Invoice);
                    CashDocLn.TestField("Applies-To Doc. No.", ServInvHdr."No.");
                end;
            PaymentMethod."Cash Document Status"::Post:
                begin
                    PostedCashDocHdr.SetRange("Cash Desk No.", BankAcc."No.");
                    PostedCashDocHdr.SetRange("Cash Document Type", PostedCashDocHdr."Cash Document Type"::Receipt);
                    PostedCashDocHdr.SetRange("Posting Date", ServInvHdr."Posting Date");
                    PostedCashDocHdr.FindLast;

                    PostedCashDocLn.SetRange("Cash Desk No.", PostedCashDocHdr."Cash Desk No.");
                    PostedCashDocLn.SetRange("Cash Document No.", PostedCashDocHdr."No.");
                    PostedCashDocLn.FindFirst;

                    PostedCashDocLn.TestField("Account Type", PostedCashDocLn."Account Type"::Customer);
                    PostedCashDocLn.TestField("Account No.", ServInvHdr."Bill-to Customer No.");
                    PostedCashDocLn.TestField("Applies-To Doc. Type", PostedCashDocLn."Applies-To Doc. Type"::Invoice);
                    PostedCashDocLn.TestField("Applies-To Doc. No.", ServInvHdr."No.");
                end;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatingWithdrawalCashDocumentFromPurchaseCrMemo()
    begin
        WithdrawalCashDocumentFromPurchaseCrMemo(1); // Create
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasingWithdrawalCashDocumentFromPurchaseCrMemo()
    begin
        WithdrawalCashDocumentFromPurchaseCrMemo(2); // Release
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingWithdrawalCashDocumentFromPurchaseCrMemo()
    begin
        WithdrawalCashDocumentFromPurchaseCrMemo(3); // Post
    end;

    local procedure WithdrawalCashDocumentFromPurchaseCrMemo(CashDocumentStatus: Option)
    var
        BankAcc: Record "Bank Account";
        CashDocHdr: Record "Cash Document Header";
        CashDocLn: Record "Cash Document Line";
        PaymentMethod: Record "Payment Method";
        ServCrMemoHdr: Record "Service Cr.Memo Header";
        ServHdr: Record "Service Header";
        ServLn: Record "Service Line";
        PostedCashDocHdr: Record "Posted Cash Document Header";
        PostedCashDocLn: Record "Posted Cash Document Line";
        PostDocNo: Code[20];
    begin
        // 1.Setup
        Initialize;

        CreateCashDesk(BankAcc);
        CreatePaymentMethod(PaymentMethod, BankAcc."No.", CashDocumentStatus);
        CreateServiceCreditMemo(ServHdr, ServLn);
        ModifyPaymentMethodInServiceDocument(ServHdr, PaymentMethod);

        // 2. Exercise
        PostDocNo := PostServiceDocument(ServHdr);

        // 3. Verify
        ServCrMemoHdr.Get(PostDocNo);

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
                    CashDocHdr.SetRange("Posting Date", ServCrMemoHdr."Posting Date");
                    CashDocHdr.FindLast;

                    CashDocLn.SetRange("Cash Desk No.", CashDocHdr."Cash Desk No.");
                    CashDocLn.SetRange("Cash Document No.", CashDocHdr."No.");
                    CashDocLn.FindFirst;

                    CashDocLn.TestField("Account Type", CashDocLn."Account Type"::Customer);
                    CashDocLn.TestField("Account No.", ServCrMemoHdr."Bill-to Customer No.");
                    CashDocLn.TestField("Applies-To Doc. Type", CashDocLn."Applies-To Doc. Type"::"Credit Memo");
                    CashDocLn.TestField("Applies-To Doc. No.", ServCrMemoHdr."No.");
                end;
            PaymentMethod."Cash Document Status"::Post:
                begin
                    PostedCashDocHdr.SetRange("Cash Desk No.", BankAcc."No.");
                    PostedCashDocHdr.SetRange("Cash Document Type", PostedCashDocHdr."Cash Document Type"::Withdrawal);
                    PostedCashDocHdr.SetRange("Posting Date", ServCrMemoHdr."Posting Date");
                    PostedCashDocHdr.FindLast;

                    PostedCashDocLn.SetRange("Cash Desk No.", PostedCashDocHdr."Cash Desk No.");
                    PostedCashDocLn.SetRange("Cash Document No.", PostedCashDocHdr."No.");
                    PostedCashDocLn.FindFirst;

                    PostedCashDocLn.TestField("Account Type", PostedCashDocLn."Account Type"::Customer);
                    PostedCashDocLn.TestField("Account No.", ServCrMemoHdr."Bill-to Customer No.");
                    PostedCashDocLn.TestField("Applies-To Doc. Type", PostedCashDocLn."Applies-To Doc. Type"::"Credit Memo");
                    PostedCashDocLn.TestField("Applies-To Doc. No.", ServCrMemoHdr."No.");
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

    local procedure CreateServiceDocument(var ServHdr: Record "Service Header"; var ServLn: Record "Service Line"; DocumentType: Option; Amount: Decimal)
    begin
        LibraryService.CreateServiceHeader(ServHdr, DocumentType, '');
        LibraryService.CreateServiceLine(ServLn, ServHdr, ServLn.Type::Item, '');
        ServLn.Validate(Quantity, 1);
        ServLn.Validate("Unit Price", Amount);
        ServLn.Modify(true);
    end;

    local procedure CreateServiceCreditMemo(var ServHdr: Record "Service Header"; var ServLn: Record "Service Line")
    begin
        CreateServiceDocument(ServHdr, ServLn, ServHdr."Document Type"::"Credit Memo", LibraryRandom.RandDec(10000, 2));
    end;

    local procedure CreateServiceInvoice(var ServHdr: Record "Service Header"; var ServLn: Record "Service Line")
    begin
        CreateServiceDocument(ServHdr, ServLn, ServHdr."Document Type"::Invoice, LibraryRandom.RandDec(10000, 2));
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

    local procedure ModifyPaymentMethodInServiceDocument(var ServHdr: Record "Service Header"; PaymentMethod: Record "Payment Method")
    begin
        ServHdr.Validate("Payment Method Code", PaymentMethod.Code);
        ServHdr.Modify();
    end;

    local procedure PostServiceDocument(var ServHdr: Record "Service Header"): Code[20]
    var
        ServInvHdr: Record "Service Invoice Header";
        ServCrMemoHdr: Record "Service Cr.Memo Header";
    begin
        LibraryService.PostServiceOrder(ServHdr, true, false, true);

        ServInvHdr.SetRange("Pre-Assigned No.", ServHdr."No.");
        if ServInvHdr.FindFirst then
            exit(ServInvHdr."No.");

        ServCrMemoHdr.SetRange("Pre-Assigned No.", ServHdr."No.");
        if ServCrMemoHdr.FindFirst then
            exit(ServCrMemoHdr."No.");
    end;
}

