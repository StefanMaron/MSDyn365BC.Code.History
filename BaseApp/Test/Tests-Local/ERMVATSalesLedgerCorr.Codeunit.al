codeunit 147201 "ERM VAT Sales Ledger Corr."
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        VATLedgerLineCntErr: Label 'VAT Ledger lines count is incorrect';
        LibraryPurchase: Codeunit "Library - Purchase";
        UnitPrice: Decimal;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure SC1_InvCorrInv()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateInvoice(SalesHeader, CalcDate('<CQ-1D>', WorkDate()), CustNo);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2_InvCorrCrMemo()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<CQ-1D>', WorkDate()), CustNo);
        UpdateInclInPurchVATLedger(SalesHeader, true);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);

        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, CustNo, false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, CustNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3_InvCorrInvDiffPeriod()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateInvoice(SalesHeader, CalcDate('<CQ+1D>', WorkDate()), CustNo);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);

        StartDate := CalcDate('<-CQ>', CalcDate('<CQ+1D>', WorkDate()));
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC4_InvCorrCrMemoDiffPeriod()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<CQ+1D>', WorkDate()), CustNo);
        UpdateInclInPurchVATLedger(SalesHeader, true);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);

        StartDate := CalcDate('<-CQ>', CalcDate('<CQ+1D>', WorkDate()));
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, '', false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, CustNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC5_InvTwoCorrInv()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateInvoice(SalesHeader, CalcDate('<1D>', WorkDate()), CustNo);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateInvoice(SalesHeader, CalcDate('<10D>', WorkDate()), CustNo);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6_InvTwoCorrCrMemo()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<1D>', WorkDate()), CustNo);
        UpdateInclInPurchVATLedger(SalesHeader, true);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<10D>', WorkDate()), CustNo);
        UpdateInclInPurchVATLedger(SalesHeader, true);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::"Credit Memo", PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);

        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, '', false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, CustNo, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC7_InvCorrInvCorrCrMemo()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateInvoice(SalesHeader, CalcDate('<1D>', WorkDate()), CustNo);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<10D>', WorkDate()), CustNo);
        UpdateInclInPurchVATLedger(SalesHeader, true);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 2);

        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, '', false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, CustNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC8_InvCorrInvCorrCrMemoDP()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateInvoice(SalesHeader, CalcDate('<1D>', WorkDate()), CustNo);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<CQ+1D>', WorkDate()), CustNo);
        UpdateInclInPurchVATLedger(SalesHeader, true);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 2);

        StartDate := CalcDate('<CQ+1D>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, '', false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, CustNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC9_InvCorrCrMemoCorrInvDP()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<1D>', WorkDate()), CustNo);
        UpdateInclInPurchVATLedger(SalesHeader, true);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateInvoice(SalesHeader, CalcDate('<CQ+1D>', WorkDate()), CustNo);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::"Credit Memo", PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);

        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, '', false, true);
        VerifyPurchVATLedgerLineCnt(VATLedgerCode, CustNo, 1);

        StartDate := CalcDate('<CQ+1D>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC10_InvCorrCrMemoDP()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<CQ+1D>', WorkDate()), CustNo);
        UpdateAddVATLedgSheet(SalesHeader, true);
        UpdateCorrDocDate(SalesHeader, WorkDate());
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo);
        CreateSalesCorrLine(SalesHeader);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);

        LibrarySales.CreateSalesVATLedgerAddSheet(VATLedgerCode);
        VerifySalesVATLedgerAddLineCnt(VATLedgerCode, CustNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC11_InvRevCrMemoRevInvDP()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<CQ-1D>', WorkDate()), CustNo);
        UpdateRevisionInfo(SalesHeader, true, PostedDocNo, 'CrMemoRev1');
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice / 2);
        PostSalesDoc(SalesHeader);

        CreateInvoice(SalesHeader, CalcDate('<CQ+1D>', WorkDate()), CustNo);
        UpdateRevisionInfo(SalesHeader, true, PostedDocNo, 'InvRev1');
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice * 2);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 2);

        StartDate := CalcDate('<-CQ>', CalcDate('<CQ+1D>', WorkDate()));
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC12_InvRevCrMemoRevInvDPAddSh()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<CQ+1D>', WorkDate()), CustNo);
        UpdateAddVATLedgSheet(SalesHeader, true);
        UpdateCorrDocDate(SalesHeader, WorkDate());
        UpdateRevisionInfo(SalesHeader, true, PostedDocNo, 'CrMemoRev1');
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice / 2);
        PostSalesDoc(SalesHeader);

        CreateInvoice(SalesHeader, CalcDate('<CQ+2D>', WorkDate()), CustNo);
        UpdateRevisionInfo(SalesHeader, true, PostedDocNo, 'InvRev1');
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice * 2);
        PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        LibrarySales.CreateSalesVATLedgerAddSheet(VATLedgerCode);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);
        VerifySalesVATLedgerAddLineCnt(VATLedgerCode, CustNo, 1);

        StartDate := CalcDate('<-CQ>', CalcDate('<CQ+1D>', WorkDate()));
        EndDate := CalcDate('<CQ>', StartDate);
        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifySalesVATLedgerLineCnt(VATLedgerCode, CustNo, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS_325343()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PostedDocNo: array[4] of Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo[1] := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<CQ+1D>', WorkDate()), CustNo);
        UpdateInclInPurchVATLedger(SalesHeader, true);
        UpdateCorrectionInfo(SalesHeader, SalesHeader."Corrected Doc. Type"::Invoice, PostedDocNo[1]);
        CreateSalesCorrLine(SalesHeader);
        PostedDocNo[2] := PostSalesDoc(SalesHeader);

        CreateInvoice(SalesHeader, CalcDate('<CQ+2D>', WorkDate()), CustNo);
        UpdateRevisionInfo(SalesHeader, false, PostedDocNo[2], 'Rev2');
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo[3] := PostSalesDoc(SalesHeader);

        CreateCrMemo(SalesHeader, CalcDate('<CQ+3D>', WorkDate()), CustNo);
        UpdateInclInPurchVATLedger(SalesHeader, true);
        UpdateRevisionInfo(SalesHeader, false, PostedDocNo[2], 'Rev2');
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        PostedDocNo[4] := PostSalesDoc(SalesHeader);

        StartDate := CalcDate('<-CQ>', CalcDate('<CQ+1D>', WorkDate()));
        EndDate := CalcDate('<CQ>', StartDate);

        VATLedgerCode := LibraryPurchase.CreatePurchaseVATLedger(StartDate, EndDate, CustNo, false, true);
        VerifyCrMemoPurchVATLedgerLine(
          VATLedgerCode, CustNo,
          PostedDocNo[1], WorkDate(), PostedDocNo[2], CalcDate('<CQ+1D>', WorkDate()), '', 0D, '', 0D);
        VerifyCrMemoPurchVATLedgerLine(
          VATLedgerCode, CustNo,
          PostedDocNo[1], WorkDate(), PostedDocNo[2], CalcDate('<CQ+1D>', WorkDate()), '', 0D, 'Rev2', CalcDate('<CQ+3D>', WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInSamePeriod()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PrepmtInvDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        ReleaseInvoice(SalesHeader);
        CreatePostPrepmt(CalcDate('<CQ+10D>', WorkDate()), CustNo, SalesHeader."No.");
        PrepmtInvDocNo := GetLastPrepmtInvoice(CustNo);

        StartDate := CalcDate('<-CQ>', WorkDate());
        EndDate := CalcDate('<CQ+1M>', StartDate);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifyPrepmtInvVATLedgerLine(
          VATLedgerCode, CustNo,
          PrepmtInvDocNo, CalcDate('<CQ+10D>', WorkDate()), '', 0D, '', 0D, '', 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInOtherPeriod()
    var
        SalesHeader: Record "Sales Header";
        CustNo: Code[20];
        PrepmtInvDocNo: Code[20];
        GLAccountNo: Code[20];
        VATLedgerCode: Code[20];
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize();
        CreateCustomerGLAccount(CustNo, GLAccountNo);

        CreateInvoice(SalesHeader, WorkDate(), CustNo);
        CreateSalesLine(SalesHeader, GLAccountNo, UnitPrice);
        ReleaseInvoice(SalesHeader);
        CreatePostPrepmt(CalcDate('<-1M>', WorkDate()), CustNo, SalesHeader."No.");
        PrepmtInvDocNo := GetLastPrepmtInvoice(CustNo);

        StartDate := CalcDate('<-CM-1M>', WorkDate());
        EndDate := CalcDate('<-CM-1D>', WorkDate());

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(StartDate, EndDate, CustNo);
        VerifyPrepmtInvVATLedgerLine(
          VATLedgerCode, CustNo,
          PrepmtInvDocNo, CalcDate('<-1M>', WorkDate()), '', 0D, '', 0D, '', 0D);
    end;

    local procedure UpdateCorrectionInfo(var SalesHeader: Record "Sales Header"; CorrDocType: Option; CorrDocNo: Code[20])
    begin
        with SalesHeader do begin
            Validate("Corrective Document", true);
            Validate("Corrective Doc. Type", "Corrective Doc. Type"::Correction);
            Validate("Corrected Doc. Type", CorrDocType);
            Validate("Corrected Doc. No.", CorrDocNo);
            Modify(true);
        end;
    end;

    local procedure UpdateRevisionInfo(var SalesHeader: Record "Sales Header"; IsCorrInvoice: Boolean; CorrDocNo: Code[20]; RevisionNo: Code[20])
    begin
        with SalesHeader do begin
            Validate("Corrective Document", true);
            Validate("Corrective Doc. Type", "Corrective Doc. Type"::Revision);
            if IsCorrInvoice then
                Validate("Corrected Doc. Type", "Corrected Doc. Type"::Invoice)
            else
                Validate("Corrected Doc. Type", "Corrected Doc. Type"::"Credit Memo");
            Validate("Corrected Doc. No.", CorrDocNo);
            Validate("Revision No.", RevisionNo);
            Modify(true);
        end;
    end;

    local procedure UpdateInclInPurchVATLedger(var SalesHeader: Record "Sales Header"; IsIncludeInSalesVATLedger: Boolean)
    begin
        with SalesHeader do begin
            Validate("Include In Purch. VAT Ledger", IsIncludeInSalesVATLedger);
            Modify(true);
        end;
    end;

    local procedure UpdateAddVATLedgSheet(var SalesHeader: Record "Sales Header"; IsAddVATLedgetSheet: Boolean)
    begin
        with SalesHeader do begin
            Validate("Additional VAT Ledger Sheet", IsAddVATLedgetSheet);
            Modify(true);
        end;
    end;

    local procedure UpdateCorrDocDate(var SalesHeader: Record "Sales Header"; CorrDocDate: Date)
    begin
        with SalesHeader do begin
            Validate("Corrected Document Date", CorrDocDate);
            Modify(true);
        end;
    end;

    local procedure PostSalesDoc(SalesHeader: Record "Sales Header"): Code[20]
    begin
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostPrepmt(PostingDate: Date; CustNo: Code[20]; PrepmtDocNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        with GenJournalLine do begin
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
              "Document Type"::Payment, "Account Type"::Customer, CustNo, 0);
            Validate("Posting Date", PostingDate);
            Validate(Prepayment, true);
            "External Document No." := LibraryUtility.GenerateGUID();
            Validate("Prepayment Document No.", PrepmtDocNo);
            Validate("Bal. Account Type", "Bal. Account Type"::"G/L Account");
            Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo);
            Modify(true);
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateInvoice(var SalesHeader: Record "Sales Header"; PostingDate: Date; CustNo: Code[20])
    begin
        CreateSalesDoc(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          PostingDate, CustNo);
    end;

    local procedure CreateCrMemo(var SalesHeader: Record "Sales Header"; PostingDate: Date; CustNo: Code[20])
    begin
        CreateSalesDoc(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo",
          PostingDate, CustNo);
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; PostingDate: Date; CustNo: Code[20])
    begin
        with SalesHeader do begin
            LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustNo);
            SetHideValidationDialog(true);
            Validate("Posting Date", PostingDate);
            Validate("Prices Including VAT", true);
            Modify(true);
        end;
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; GLAccountNo: Code[20]; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        with SalesLine do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type::"G/L Account", GLAccountNo, 1);
            Validate("Unit Price", UnitPrice);
            Modify();
        end;
    end;

    local procedure CreateSalesCorrLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        SalesInvLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        CorrDocMgt: Codeunit "Corrective Document Mgt.";
    begin
        case SalesHeader."Corrected Doc. Type" of
            SalesHeader."Corrected Doc. Type"::Invoice:
                begin
                    SalesInvLine.Reset();
                    SalesInvLine.SetRange("Document No.", SalesHeader."Corrected Doc. No.");
                    SalesInvLine.FindFirst();
                    CorrDocMgt.SetSalesHeader(SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
                    CorrDocMgt.SetCorrectionType(0);
                    CorrDocMgt.CreateSalesLinesFromPstdInv(SalesInvLine);
                end;
            SalesHeader."Corrected Doc. Type"::"Credit Memo":
                begin
                    SalesCrMemoLine.Reset();
                    SalesCrMemoLine.SetRange("Document No.", SalesHeader."Corrected Doc. No.");
                    SalesCrMemoLine.FindFirst();
                    CorrDocMgt.SetSalesHeader(SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
                    CorrDocMgt.SetCorrectionType(0);
                    CorrDocMgt.CreateSalesLinesFromPstdCrMemo(SalesCrMemoLine);
                end;
        end;
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Invoice:
                begin
                    SalesLine.Validate("Unit Price (After)", SalesLine."Unit Price (Before)" + 250);
                    SalesLine.Modify
                end;
            SalesHeader."Document Type"::"Credit Memo":
                begin
                    SalesLine.Validate("Unit Price (After)", SalesLine."Unit Price (Before)" - 250);
                    SalesLine.Modify
                end;
        end;
    end;

    local procedure ReleaseInvoice(var SalesHeader: Record "Sales Header")
    var
        ReleaseDoc: Codeunit "Release Sales Document";
    begin
        ReleaseDoc.PerformManualRelease(SalesHeader);
    end;

    local procedure GetLastPrepmtInvoice(CustNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        with SalesInvoiceHeader do begin
            SetRange("Bill-to Customer No.", CustNo);
            SetRange("Prepayment Invoice", true);
            FindLast();
            exit("No.");
        end;
    end;

    local procedure VerifyPurchVATLedgerLineCnt(VATLedgerCode: Code[20]; CustNo: Code[20]; ExpectedCnt: Integer)
    var
        VATLedger: Record "VAT Ledger";
    begin
        VATLedger.Get(VATLedger.Type::Purchase, VATLedgerCode);
        VerifyVATLedgerLineCnt(false, VATLedger.Type, VATLedgerCode, CustNo, ExpectedCnt);
    end;

    local procedure VerifySalesVATLedgerLineCnt(VATLedgerCode: Code[20]; CustNo: Code[20]; ExpectedCnt: Integer)
    var
        VATLedger: Record "VAT Ledger";
    begin
        VATLedger.Get(VATLedger.Type::Sales, VATLedgerCode);
        VerifyVATLedgerLineCnt(false, VATLedger.Type, VATLedgerCode, CustNo, ExpectedCnt);
    end;

    local procedure VerifyPrepmtInvVATLedgerLine(VATLedgerCode: Code[20]; VendorNo: Code[20]; DocNo: Code[20]; DocDate: Date; CorrNo: Code[20]; CorrDate: Date; RevNo: Code[20]; RevDate: Date; RevOfCorrNo: Code[20]; RevOfCorrDate: Date)
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VerifyDocVATLedgerLine(
          false, VATLedgerLine.Type::Sales, VATLedgerCode, VendorNo,
          VATLedgerLine."Document Type"::Invoice, DocNo, DocDate, true,
          CorrNo, CorrDate, RevNo, RevDate, RevOfCorrNo, RevOfCorrDate);
    end;

    local procedure VerifySalesVATLedgerAddLineCnt(VATLedgerCode: Code[20]; CustNo: Code[20]; ExpectedCnt: Integer)
    var
        VATLedger: Record "VAT Ledger";
    begin
        VATLedger.Get(VATLedger.Type::Sales, VATLedgerCode);
        VerifyVATLedgerLineCnt(true, VATLedger.Type, VATLedgerCode, CustNo, ExpectedCnt);
    end;

    local procedure VerifyVATLedgerLineCnt(IsAddSheet: Boolean; VATLEdgerType: Option; VATLedgerCode: Code[20]; CVNo: Code[20]; ExpectedCnt: Integer)
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        with VATLedgerLine do begin
            SetRange(Type, VATLEdgerType);
            SetRange("Additional Sheet", IsAddSheet);
            SetRange(Code, VATLedgerCode);
            SetRange("C/V No.", CVNo);
            Assert.AreEqual(ExpectedCnt, Count, VATLedgerLineCntErr);
        end;
    end;

    local procedure VerifyCrMemoPurchVATLedgerLine(VATLedgerCode: Code[20]; VendorNo: Code[20]; DocNo: Code[20]; DocDate: Date; CorrNo: Code[20]; CorrDate: Date; RevNo: Code[20]; RevDate: Date; RevOfCorrNo: Code[20]; RevOfCorrDate: Date)
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VerifyDocVATLedgerLine(
          false, VATLedgerLine.Type::Purchase, VATLedgerCode, VendorNo,
          VATLedgerLine."Document Type"::"Credit Memo", DocNo, DocDate, false,
          CorrNo, CorrDate, RevNo, RevDate, RevOfCorrNo, RevOfCorrDate);
    end;

    local procedure VerifyDocVATLedgerLine(IsAddSheet: Boolean; VATLEdgerType: Option; VATLedgerCode: Code[20]; CVNo: Code[20]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; DocDate: Date; IsPrepmt: Boolean; CorrNo: Code[20]; CorrDate: Date; RevNo: Code[20]; RevDate: Date; RevOfCorrNo: Code[20]; RevOfCorrDate: Date)
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        with VATLedgerLine do begin
            SetRange(Type, VATLEdgerType);
            SetRange("Additional Sheet", IsAddSheet);
            SetRange(Code, VATLedgerCode);
            SetRange("C/V No.", CVNo);
            SetRange("Document Type", DocType);
            SetRange("Document No.", DocNo);
            SetRange("Document Date", DocDate);
            SetRange(Prepayment, IsPrepmt);
            SetRange("Correction No.", CorrNo);
            SetRange("Correction Date", CorrDate);
            SetRange("Revision No.", RevNo);
            SetRange("Revision Date", RevDate);
            SetRange("Revision of Corr. No.", RevOfCorrNo);
            SetRange("Revision of Corr. Date", RevOfCorrDate);
            FindFirst();
        end;
    end;

    local procedure CreateCustomerGLAccount(var CustomerNo: Code[20]; var GLAccountNo: Code[20])
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup;
    end;

    local procedure Initialize()
    var
        LibraryRandom: Codeunit "Library - Random";
    begin
        if IsInitialized then
            exit;

        UnitPrice := LibraryRandom.RandDec(10000, 2);

        IsInitialized := true;
    end;
}

