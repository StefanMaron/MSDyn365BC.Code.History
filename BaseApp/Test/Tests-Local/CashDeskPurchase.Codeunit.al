codeunit 144102 "Cash Desk Purchase"
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
        LibraryPurchase: Codeunit "Library - Purchase";
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
        Commit;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatingWithdrawalCashDocumentFromPurchaseInvoice()
    begin
        WithdrawalCashDocumentFromPurchaseInvoice(1); // Create
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasingWithdrawalCashDocumentFromPurchaseInvoice()
    begin
        WithdrawalCashDocumentFromPurchaseInvoice(2); // Release
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingWithdrawalCashDocumentFromPurchaseInvoice()
    begin
        WithdrawalCashDocumentFromPurchaseInvoice(3); // Post
    end;

    local procedure WithdrawalCashDocumentFromPurchaseInvoice(CashDocumentStatus: Option)
    var
        BankAcc: Record "Bank Account";
        CashDocHdr: Record "Cash Document Header";
        CashDocLn: Record "Cash Document Line";
        PaymentMethod: Record "Payment Method";
        PurchInvHdr: Record "Purch. Inv. Header";
        PurchHdr: Record "Purchase Header";
        PurchLn: Record "Purchase Line";
        PostedCashDocHdr: Record "Posted Cash Document Header";
        PostedCashDocLn: Record "Posted Cash Document Line";
        PostDocNo: Code[20];
    begin
        // 1.Setup
        Initialize;

        CreateCashDesk(BankAcc);
        CreatePaymentMethod(PaymentMethod, BankAcc."No.", CashDocumentStatus);
        CreatePurchInvoice(PurchHdr, PurchLn);
        ModifyPaymentMethodInPurchaseDocument(PurchHdr, PaymentMethod);

        // 2. Exercise
        PostDocNo := PostPurchaseDocument(PurchHdr);

        // 3. Verify
        PurchInvHdr.Get(PostDocNo);
        PurchInvHdr.CalcFields("Amount Including VAT");

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
                    CashDocHdr.SetRange("Posting Date", PurchInvHdr."Posting Date");
                    CashDocHdr.FindLast;

                    CashDocLn.SetRange("Cash Desk No.", CashDocHdr."Cash Desk No.");
                    CashDocLn.SetRange("Cash Document No.", CashDocHdr."No.");
                    CashDocLn.FindFirst;

                    CashDocLn.TestField("Account Type", CashDocLn."Account Type"::Vendor);
                    CashDocLn.TestField("Account No.", PurchInvHdr."Buy-from Vendor No.");
                    CashDocLn.TestField(Amount, PurchInvHdr."Amount Including VAT");
                    CashDocLn.TestField("Applies-To Doc. Type", CashDocLn."Applies-To Doc. Type"::Invoice);
                    CashDocLn.TestField("Applies-To Doc. No.", PurchInvHdr."No.");
                end;
            PaymentMethod."Cash Document Status"::Post:
                begin
                    PostedCashDocHdr.SetRange("Cash Desk No.", BankAcc."No.");
                    PostedCashDocHdr.SetRange("Cash Document Type", PostedCashDocHdr."Cash Document Type"::Withdrawal);
                    PostedCashDocHdr.SetRange("Posting Date", PurchInvHdr."Posting Date");
                    PostedCashDocHdr.FindLast;

                    PostedCashDocLn.SetRange("Cash Desk No.", PostedCashDocHdr."Cash Desk No.");
                    PostedCashDocLn.SetRange("Cash Document No.", PostedCashDocHdr."No.");
                    PostedCashDocLn.FindFirst;

                    PostedCashDocLn.TestField("Account Type", PostedCashDocLn."Account Type"::Vendor);
                    PostedCashDocLn.TestField("Account No.", PurchInvHdr."Buy-from Vendor No.");
                    PostedCashDocLn.TestField(Amount, PurchInvHdr."Amount Including VAT");
                    PostedCashDocLn.TestField("Applies-To Doc. Type", PostedCashDocLn."Applies-To Doc. Type"::Invoice);
                    PostedCashDocLn.TestField("Applies-To Doc. No.", PurchInvHdr."No.");
                end;
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatingReceiptCashDocumentFromPurchaseCrMemo()
    begin
        ReceiptCashDocumentFromPurchaseCrMemo(1); // Create
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasingReceiptCashDocumentFromPurchaseCrMemo()
    begin
        ReceiptCashDocumentFromPurchaseCrMemo(2); // Release
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingReceiptCashDocumentFromPurchaseCrMemo()
    begin
        ReceiptCashDocumentFromPurchaseCrMemo(3); // Post
    end;

    local procedure ReceiptCashDocumentFromPurchaseCrMemo(CashDocumentStatus: Option)
    var
        BankAcc: Record "Bank Account";
        CashDocHdr: Record "Cash Document Header";
        CashDocLn: Record "Cash Document Line";
        PaymentMethod: Record "Payment Method";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchHdr: Record "Purchase Header";
        PurchLn: Record "Purchase Line";
        PostedCashDocHdr: Record "Posted Cash Document Header";
        PostedCashDocLn: Record "Posted Cash Document Line";
        PostDocNo: Code[20];
    begin
        // 1.Setup
        Initialize;

        CreateCashDesk(BankAcc);
        CreatePaymentMethod(PaymentMethod, BankAcc."No.", CashDocumentStatus);
        CreatePurchCreditMemo(PurchHdr, PurchLn);
        ModifyPaymentMethodInPurchaseDocument(PurchHdr, PaymentMethod);

        // 2. Exercise
        PostDocNo := PostPurchaseDocument(PurchHdr);

        // 3. Verify
        PurchCrMemoHdr.Get(PostDocNo);
        PurchCrMemoHdr.CalcFields("Amount Including VAT");

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
                    CashDocHdr.SetRange("Posting Date", PurchCrMemoHdr."Posting Date");
                    CashDocHdr.FindLast;

                    CashDocLn.SetRange("Cash Desk No.", CashDocHdr."Cash Desk No.");
                    CashDocLn.SetRange("Cash Document No.", CashDocHdr."No.");
                    CashDocLn.FindFirst;

                    CashDocLn.TestField("Account Type", CashDocLn."Account Type"::Vendor);
                    CashDocLn.TestField("Account No.", PurchCrMemoHdr."Buy-from Vendor No.");
                    CashDocLn.TestField(Amount, PurchCrMemoHdr."Amount Including VAT");
                    CashDocLn.TestField("Applies-To Doc. Type", CashDocLn."Applies-To Doc. Type"::"Credit Memo");
                    CashDocLn.TestField("Applies-To Doc. No.", PurchCrMemoHdr."No.");
                end;
            PaymentMethod."Cash Document Status"::Post:
                begin
                    PostedCashDocHdr.SetRange("Cash Desk No.", BankAcc."No.");
                    PostedCashDocHdr.SetRange("Cash Document Type", PostedCashDocHdr."Cash Document Type"::Receipt);
                    PostedCashDocHdr.SetRange("Posting Date", PurchCrMemoHdr."Posting Date");
                    PostedCashDocHdr.FindLast;

                    PostedCashDocLn.SetRange("Cash Desk No.", PostedCashDocHdr."Cash Desk No.");
                    PostedCashDocLn.SetRange("Cash Document No.", PostedCashDocHdr."No.");
                    PostedCashDocLn.FindFirst;

                    PostedCashDocLn.TestField("Account Type", PostedCashDocLn."Account Type"::Vendor);
                    PostedCashDocLn.TestField("Account No.", PurchCrMemoHdr."Buy-from Vendor No.");
                    PostedCashDocLn.TestField(Amount, PurchCrMemoHdr."Amount Including VAT");
                    PostedCashDocLn.TestField("Applies-To Doc. Type", PostedCashDocLn."Applies-To Doc. Type"::"Credit Memo");
                    PostedCashDocLn.TestField("Applies-To Doc. No.", PurchCrMemoHdr."No.");
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
        PaymentMethod.Modify;
    end;

    local procedure CreatePurchDocument(var PurchHdr: Record "Purchase Header"; var PurchLn: Record "Purchase Line"; DocumentType: Option; Amount: Decimal)
    var
        Vend: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vend);
        LibraryPurchase.CreatePurchHeader(PurchHdr, DocumentType, Vend."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchLn, PurchHdr, PurchLn.Type::"G/L Account", GetNewGLAccountNo(true), 1);
        PurchLn.Validate("Direct Unit Cost", Amount);
        PurchLn.Modify(true);
    end;

    local procedure CreatePurchCreditMemo(var PurchHdr: Record "Purchase Header"; var PurchLn: Record "Purchase Line")
    begin
        CreatePurchDocument(PurchHdr, PurchLn, PurchHdr."Document Type"::"Credit Memo", LibraryRandom.RandDec(10000, 2));
    end;

    local procedure CreatePurchInvoice(var PurchHdr: Record "Purchase Header"; var PurchLn: Record "Purchase Line")
    begin
        CreatePurchDocument(PurchHdr, PurchLn, PurchHdr."Document Type"::Invoice, LibraryRandom.RandDec(10000, 2));
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

    local procedure ModifyPaymentMethodInPurchaseDocument(var PurchHdr: Record "Purchase Header"; PaymentMethod: Record "Payment Method")
    begin
        PurchHdr.Validate("Payment Method Code", PaymentMethod.Code);
        PurchHdr.Modify;
    end;

    local procedure PostPurchaseDocument(var PurchHdr: Record "Purchase Header"): Code[20]
    begin
        exit(LibraryPurchase.PostPurchaseDocument(PurchHdr, true, true));
    end;
}

