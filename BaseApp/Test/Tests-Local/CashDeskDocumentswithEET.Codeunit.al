codeunit 144104 "Cash Desk Documents with EET"
{
    // // [FEATURE] [EET] [Cash Desk]

    Subtype = Test;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryCashDesk: Codeunit "Library - Cash Desk";
        LibraryCertificate: Codeunit "Library - Certificate";
        LibraryEET: Codeunit "Library - EET";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        EETTransactionErr: Label 'Cash Document Line must be marked as a EET Transaction.';
        IsInitialized: Boolean;
        ItCannotBeZeroOrEmptyErr: Label 'It cannot be zero or empty.';

    [Test]
    [Scope('OnPrem')]
    procedure CheckEETTransactionForReceipt()
    begin
        // [SCENARIO] Check whether EET transaction field = true for combination of receipt cash document and sales invoice
        // [GIVEN] Create and post sales invoice
        // [GIVEN] Create receipt cash document
        CheckEETTransaction(2, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckEETTransactionForWithdrawal()
    begin
        // [SCENARIO] Check whether EET transaction field = true for combination of withdrawal cash document and sales credit memo
        // [GIVEN] Create and post sales credit memo
        // [GIVEN] Create withdrawal cash document
        CheckEETTransaction(3, 2);
    end;

    local procedure CheckEETTransaction(SalesDocumentType: Option; CashDocumentType: Option)
    var
        CashDocumentHeader: Record "Cash Document Header";
        CashDocumentLine: Record "Cash Document Line";
        SalesHeader: Record "Sales Header";
        PostedDocumentNo: Code[20];
        AppliesToDocType: Option;
    begin
        Initialize;

        PostedDocumentNo := CreateAndPostSalesDocument(SalesHeader, SalesDocumentType);
        AppliesToDocType := ConvertDocTypeToAppliesToDocType(SalesDocumentType);

        CreateCashDocumentHeader(CashDocumentHeader, CashDocumentType, CreateCashDeskNo);

        // [WHEN] Create cash document line with apply
        CreateCashDocumentLineWithApply(
          CashDocumentLine, CashDocumentHeader, CashDocumentLine."Account Type"::Customer,
          SalesHeader."Sell-to Customer No.", AppliesToDocType, PostedDocumentNo);

        // [THEN] EET Transaction on the cash document line must be TRUE
        Assert.IsTrue(CashDocumentLine."EET Transaction", EETTransactionErr);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostReceiptCashDocumentWithAppliesToInvoice()
    begin
        // [SCENARIO] Post receipt cash document with registrated sale and applies to sales invoice
        // [GIVEN] Create and post sales invoice
        // [GIVEN] Create receipt cash document with one line which applies to created invoice
        PostCashDocumentWithAppliesTo(2, 1);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostWithdrawalCashDocumentWithAppliesToCreditMemo()
    begin
        // [SCENARIO] Post withdrawal cash document with registrated sale and applies to sales credit memo
        // [GIVEN] Create and post sales credit memo
        // [GIVEN] Create withdrawal cash document with one line which applies to created credit memo
        PostCashDocumentWithAppliesTo(3, 2);
    end;

    local procedure PostCashDocumentWithAppliesTo(SalesDocumentType: Option; CashDocumentType: Option)
    var
        CashDocumentHeader: Record "Cash Document Header";
        CashDocumentLine: Record "Cash Document Line";
        SalesHeader: Record "Sales Header";
        PostedDocumentNo: Code[20];
        AppliesToDocType: Option;
    begin
        Initialize;

        PostedDocumentNo := CreateAndPostSalesDocument(SalesHeader, SalesDocumentType);
        AppliesToDocType := ConvertDocTypeToAppliesToDocType(SalesDocumentType);

        CreateCashDocumentHeader(CashDocumentHeader, CashDocumentType, CreateCashDeskNo);
        CreateCashDocumentLineWithApply(
          CashDocumentLine, CashDocumentHeader, CashDocumentLine."Account Type"::Customer,
          SalesHeader."Sell-to Customer No.", AppliesToDocType, PostedDocumentNo);

        // [WHEN] Post cash document
        PostCashDocument(CashDocumentHeader);

        // [THEN] EET entries are exist
        VerifyEETEntries(CashDocumentHeader);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostReceiptCashDocumentWithCashDeskEvent()
    var
        CashDeskEvent: Record "Cash Desk Event";
        CashDocumentHeader: Record "Cash Document Header";
        CashDocumentLine: Record "Cash Document Line";
        SalesHeader: Record "Sales Header";
        CashDeskNo: Code[20];
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO] Post receipt cash document with cash desk event and applies to sales invoice
        // [GIVEN] Create and post sales invoice
        // [GIVEN] Create receipt cash document with one line which applies to created invoice and it has cash desk event
        Initialize;

        PostedDocumentNo := CreateAndPostSalesInvoice(SalesHeader);
        CashDeskNo := CreateCashDeskNo;

        CreateCashDeskEvent(
          CashDeskEvent, CashDeskNo, CashDeskEvent."Document Type"::Payment,
          CashDeskEvent."Account Type"::Customer, SalesHeader."Sell-to Customer No.");
        CreateCashDocumentHeader(CashDocumentHeader, CashDocumentHeader."Cash Document Type"::Receipt, CashDeskNo);
        CreateCashDocumentLineWithEvent(
          CashDocumentLine, CashDocumentHeader, CashDeskEvent.Code,
          CashDocumentLine."Applies-To Doc. Type"::Invoice, PostedDocumentNo);

        // [WHEN] Post cash document
        PostCashDocument(CashDocumentHeader);

        // [THEN] EET entries are exist
        VerifyEETEntries(CashDocumentHeader);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostReceiptCashDocumentWithTwoLinesAndOneRegistratedSale()
    var
        CashDocumentHeader: Record "Cash Document Header";
        CashDocumentLine: Record "Cash Document Line";
        SalesHeader: Record "Sales Header";
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO] Post receipt cash document with two lines and only one line with registrated sale.
        // If one line is with registered sale and second line not then error occurs
        // [GIVEN] Create and post sales invoice
        // [GIVEN] Create receipt cash document with one line which is registered sale and second line which is not registered sale
        Initialize;

        PostedDocumentNo := CreateAndPostSalesInvoice(SalesHeader);

        CreateCashDocumentHeader(CashDocumentHeader, CashDocumentHeader."Cash Document Type"::Receipt, CreateCashDeskNo);
        CreateCashDocumentLineWithApply(
          CashDocumentLine, CashDocumentHeader,
          CashDocumentLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          CashDocumentLine."Applies-To Doc. Type"::Invoice, PostedDocumentNo);
        CreateCashDocumentLine(
          CashDocumentLine, CashDocumentHeader,
          CashDocumentLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          LibraryRandom.RandDec(GetMaxAmountLimit, 2));

        // [WHEN] Post cash document
        asserterror PostCashDocument(CashDocumentHeader);

        // [THEN] Error occurs
        Assert.ExpectedError(ItCannotBeZeroOrEmptyErr);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostReceiptCashDocumentWithTwoLinesAndOneCashDeskEvent()
    var
        CashDeskEvent: Record "Cash Desk Event";
        CashDocumentHeader: Record "Cash Document Header";
        CashDocumentLine: Record "Cash Document Line";
        SalesHeader: Record "Sales Header";
        CashDeskNo: Code[20];
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO] Post receipt cash document with two lines and only one line with cash desk event.
        // If one line has cash desk event and second line not then error occurs
        // [GIVEN] Create and post sales invoice
        // [GIVEN] Create receipt cash document with one line which has cash desk event and
        // second line which has not cash desk event
        Initialize;

        PostedDocumentNo := CreateAndPostSalesInvoice(SalesHeader);
        CashDeskNo := CreateCashDeskNo;

        CreateCashDeskEvent(
          CashDeskEvent, CashDeskNo, CashDeskEvent."Document Type"::Payment,
          CashDeskEvent."Account Type"::Customer, SalesHeader."Sell-to Customer No.");
        CreateCashDocumentHeader(CashDocumentHeader, CashDocumentHeader."Cash Document Type"::Receipt, CashDeskNo);
        CreateCashDocumentLineWithEvent(
          CashDocumentLine, CashDocumentHeader, CashDeskEvent.Code,
          CashDocumentLine."Applies-To Doc. Type"::Invoice, PostedDocumentNo);
        CreateCashDocumentLineWithApply(
          CashDocumentLine, CashDocumentHeader,
          CashDocumentLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          CashDocumentLine."Applies-To Doc. Type"::Invoice, PostedDocumentNo);

        // [WHEN] Post cash document
        asserterror PostCashDocument(CashDocumentHeader);

        // [THEN] Error occurs
        Assert.ExpectedError(ItCannotBeZeroOrEmptyErr);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostReceiptCashDocumentWithoutCertificate()
    var
        CashDocumentHeader: Record "Cash Document Header";
        CashDocumentLine: Record "Cash Document Line";
        SalesHeader: Record "Sales Header";
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO] Post receipt cash with registered sale but certificate is not set up in EET service setup
        // [GIVEN] Delete certificate from EET service setup
        // [GIVEN] Create and post sales invoice
        // [GIVEN] Create receipt cash document with one line which applies to created invoice
        Initialize;
        LibraryEET.SetCertificateCode('');

        PostedDocumentNo := CreateAndPostSalesInvoice(SalesHeader);

        CreateCashDocumentHeader(CashDocumentHeader, CashDocumentHeader."Cash Document Type"::Receipt, CreateCashDeskNo);
        CreateCashDocumentLineWithApply(
          CashDocumentLine, CashDocumentHeader,
          CashDocumentLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          CashDocumentLine."Applies-To Doc. Type"::Invoice, PostedDocumentNo);

        // [WHEN] Post cash document
        asserterror PostCashDocument(CashDocumentHeader);

        // [THEN] Error occurs
        Assert.ExpectedError(ItCannotBeZeroOrEmptyErr);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryEET.SetEnabledEETService(true);
        LibraryEET.SetCertificateCode(CreateCertificateCode);

        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"EET Service Setup");
    end;

    local procedure ConvertDocTypeToAppliesToDocType(DocumentType: Option): Integer
    var
        CashDocumentLine: Record "Cash Document Line";
        SalesHeader: Record "Sales Header";
    begin
        case DocumentType of
            SalesHeader."Document Type"::Invoice:
                exit(CashDocumentLine."Applies-To Doc. Type"::Invoice);
            SalesHeader."Document Type"::"Credit Memo":
                exit(CashDocumentLine."Applies-To Doc. Type"::"Credit Memo");
        end;
    end;

    local procedure CreateAndPostSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Option): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesHeader, SalesLine, DocumentType);
        exit(PostSalesDocument(SalesHeader));
    end;

    local procedure CreateAndPostSalesInvoice(var SalesHeader: Record "Sales Header"): Code[20]
    begin
        exit(CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice));
    end;

    local procedure CreateBankAccountPostingGroup(var BankAccPostingGroup: Record "Bank Account Posting Group"; GLAccountNo: Code[20])
    begin
        LibraryERM.CreateBankAccountPostingGroup(BankAccPostingGroup);
        BankAccPostingGroup."G/L Account No." := GLAccountNo;
        BankAccPostingGroup.Modify(true);
    end;

    local procedure CreateCashDeskEvent(var CashDeskEvent: Record "Cash Desk Event"; CashDeskNo: Code[20]; CashDocType: Option; AccountType: Option; AccountNo: Code[20])
    begin
        if AccountNo = '' then
            AccountNo := GetAccountNo(AccountType);

        LibraryCashDesk.CreateEETCashDeskEvent(CashDeskEvent, CashDeskNo, CashDocType, AccountType, AccountNo);
    end;

    local procedure CreateCashDeskUser(var CashDeskUser: Record "Cash Desk User"; CashDeskNo: Code[20])
    begin
        LibraryCashDesk.CreateCashDeskUser(CashDeskUser, CashDeskNo, true, true, true);
    end;

    local procedure CreateCashDesk(var BankAcc: Record "Bank Account")
    var
        BankAccPostingGroup: Record "Bank Account Posting Group";
        RoundingMethod: Record "Rounding Method";
        CashDeskUser: Record "Cash Desk User";
    begin
        CreateBankAccountPostingGroup(BankAccPostingGroup, CreateGLAccountNo(false));
        CreateRoundingMethod(RoundingMethod);
        CreateCashDeskBase(BankAcc, BankAccPostingGroup.Code, RoundingMethod.Code);
        CreateCashDeskUser(CashDeskUser, BankAcc."No.");
    end;

    local procedure CreateCashDeskNo(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        CreateCashDesk(BankAccount);
        exit(BankAccount."No.");
    end;

    local procedure CreateCashDeskBase(var BankAcc: Record "Bank Account"; BankAccPostingGroupCode: Code[20]; RoundingMethodCode: Code[10])
    begin
        LibraryCashDesk.CreateEETCashDesk(BankAcc);
        BankAcc."Bank Acc. Posting Group" := BankAccPostingGroupCode;
        BankAcc."Debit Rounding Account" := CreateGLAccountNo(false);
        BankAcc."Credit Rounding Account" := CreateGLAccountNo(false);
        BankAcc."Rounding Method Code" := RoundingMethodCode;
        BankAcc."Cash Receipt Limit" := GetMaxAmountLimit;
        BankAcc."Cash Withdrawal Limit" := GetMaxAmountLimit;
        BankAcc."Max. Balance" := GetMaxAmountLimit;
        BankAcc."Min. Balance" := GetMaxAmountLimit;
        BankAcc."Cash Document Receipt Nos." := LibraryUtility.GetGlobalNoSeriesCode;
        BankAcc."Cash Document Withdrawal Nos." := LibraryUtility.GetGlobalNoSeriesCode;
        BankAcc.Modify(true);
    end;

    local procedure CreateCashDocumentHeader(var CashDocumentHeader: Record "Cash Document Header"; CashDocType: Option; CashDeskNo: Code[20])
    begin
        LibraryCashDesk.CreateCashDocumentHeader(CashDocumentHeader, CashDocType, CashDeskNo);
    end;

    local procedure CreateCashDocumentLine(var CashDocumentLine: Record "Cash Document Line"; CashDocumentHeader: Record "Cash Document Header"; AccountType: Option; AccountNo: Code[20]; Amount: Decimal)
    begin
        CreateCashDocumentLineBase(
          CashDocumentLine, CashDocumentHeader, AccountType, AccountNo, Amount, 0, '');
    end;

    local procedure CreateCashDocumentLineBase(var CashDocumentLine: Record "Cash Document Line"; CashDocumentHeader: Record "Cash Document Header"; AccountType: Option; AccountNo: Code[20]; Amount: Decimal; AppliesToDocType: Option; AppliesToDocNo: Code[20])
    begin
        if AccountNo = '' then
            AccountNo := GetAccountNo(AccountType);

        LibraryCashDesk.CreateCashDocumentLine(CashDocumentLine, CashDocumentHeader, AccountType, AccountNo, Amount);

        if AppliesToDocType <> CashDocumentLine."Applies-To Doc. Type"::" " then begin
            CashDocumentLine.Validate("Applies-To Doc. Type", AppliesToDocType);
            CashDocumentLine.Validate("Applies-To Doc. No.", AppliesToDocNo);
            CashDocumentLine.Modify(true);
        end;
    end;

    local procedure CreateCashDocumentLineWithApply(var CashDocumentLine: Record "Cash Document Line"; CashDocumentHeader: Record "Cash Document Header"; AccountType: Option; AccountNo: Code[20]; AppliesToDocType: Option; AppliesToDocNo: Code[20])
    begin
        CreateCashDocumentLineBase(
          CashDocumentLine, CashDocumentHeader, AccountType, AccountNo, 0, AppliesToDocType, AppliesToDocNo);
    end;

    local procedure CreateCashDocumentLineWithEvent(var CashDocumentLine: Record "Cash Document Line"; CashDocumentHeader: Record "Cash Document Header"; CashDeskEventCode: Code[10]; AppliesToDocType: Option; AppliesToDocNo: Code[20])
    begin
        LibraryCashDesk.CreateCashDocumentLineWithCashDeskEvent(CashDocumentLine, CashDocumentHeader, CashDeskEventCode, 0);

        if AppliesToDocType <> CashDocumentLine."Applies-To Doc. Type"::" " then begin
            CashDocumentLine.Validate("Applies-To Doc. Type", AppliesToDocType);
            CashDocumentLine.Validate("Applies-To Doc. No.", AppliesToDocNo);
            CashDocumentLine.Modify(true);
        end;
    end;

    local procedure CreateCertificate(var IsolatedCertificate: Record "Isolated Certificate")
    var
        CertificateCZCode: Record "Certificate CZ Code";
    begin
        LibraryCertificate.CreateCertificateCZCode(CertificateCZCode);
        LibraryCertificate.CreateIsolatedCertificateWithWithTestBlob(IsolatedCertificate, CertificateCZCode.Code, 1);
    end;

    local procedure CreateCertificateCode(): Code[20]
    var
        IsolatedCertificate: Record "Isolated Certificate";
    begin
        CreateCertificate(IsolatedCertificate);
        exit(IsolatedCertificate."Certificate Code");
    end;

    local procedure CreateCustomerNo(): Code[20]
    begin
        exit(LibrarySales.CreateCustomerNo)
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

    local procedure CreateGLAccountNo(WithVATPostingSetup: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        CreateGLAccount(GLAccount, WithVATPostingSetup);
        exit(GLAccount."No.");
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

    local procedure CreateSalesDocument(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line"; DocumentType: Option)
    begin
        LibrarySales.CreateSalesHeader(SalesHdr, DocumentType, CreateCustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLn, SalesHdr, SalesLn.Type::"G/L Account", CreateGLAccountNo(true), 1);
        SalesLn.Validate("Unit Price", LibraryRandom.RandDec(GetMaxAmountLimit, 2));
        SalesLn.Modify(true);
    end;

    local procedure GetAccountNo(AccountType: Option): Code[20]
    var
        CashDocumentLine: Record "Cash Document Line";
    begin
        case AccountType of
            CashDocumentLine."Account Type"::"G/L Account":
                exit(CreateGLAccountNo(false));
            CashDocumentLine."Account Type"::Customer:
                exit(CreateCustomerNo);
        end;
    end;

    local procedure GetMaxAmountLimit(): Decimal
    begin
        exit(10000);
    end;

    local procedure PostCashDocument(var CashDocHdr: Record "Cash Document Header")
    begin
        LibraryCashDesk.PostCashDocument(CashDocHdr);
    end;

    local procedure PostSalesDocument(var SalesHdr: Record "Sales Header"): Code[20]
    begin
        exit(LibrarySales.PostSalesDocument(SalesHdr, true, true));
    end;

    local procedure VerifyEETEntries(CashDocumentHeader: Record "Cash Document Header")
    var
        EETEntry: Record "EET Entry";
    begin
        EETEntry.SetRange("Source Type", EETEntry."Source Type"::"Cash Desk");
        EETEntry.SetRange("Source No.", CashDocumentHeader."Cash Desk No.");
        EETEntry.SetRange("Document No.", CashDocumentHeader."No.");
        EETEntry.FindFirst;
        EETEntry.TestField("EET Status", EETEntry."EET Status"::Failure);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

