codeunit 145401 "WHT Purch.Pmt Disc. Jnl ApplTo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [WHT] [Payment Discount] [Purchase]
        IsInitialized := false;
    end;

    var
        PurchHeader: Record "Purchase Header";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        EnableGST();
        IsInitialized := true;
        Commit();
    end;

    local procedure EnableGST()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        with GLSetup do begin
            Get();
            Validate("Enable GST (Australia)", true);
            Modify();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JnlPmtLineApplIDTo2Of3PostedInv()
    begin
        JnlPmtLineApplIDTo2Of3PostedDoc(PurchHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JnlRfdLineApplIDTo2Of3PostedCrM()
    begin
        JnlPmtLineApplIDTo2Of3PostedDoc(PurchHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JnlPmtLineApplToInvLine()
    begin
        JnlPmtLineApplToDocLine(PurchHeader."Document Type"::Invoice, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JnlRfdLineApplToCrMLine()
    begin
        JnlPmtLineApplToDocLine(PurchHeader."Document Type"::"Credit Memo", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JnlPmtLineApplToPostedInvLine()
    begin
        JnlPmtLineApplToDocLine(PurchHeader."Document Type"::Invoice, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JnlRfdLineApplToPostedCrMLine()
    begin
        JnlPmtLineApplToDocLine(PurchHeader."Document Type"::"Credit Memo", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvUnderWHTLimitAppliedToPayment()
    begin
        DocUnderWHTLimitAppliedToPmt(PurchHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrMUnderWHTLimitAppliedToRefund()
    begin
        DocUnderWHTLimitAppliedToPmt(PurchHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvAppliedToPmt()
    begin
        DocAppliedToPmt(PurchHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrMAppliedToPmt()
    begin
        DocAppliedToPmt(PurchHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyFCYInvAppliedToPmt()
    begin
        UnapplyFCYDocAppliedToPmt(PurchHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyFCYCrMAppliedToPmt()
    begin
        UnapplyFCYDocAppliedToPmt(PurchHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYInvAppliedToPmt()
    begin
        FCYDocAppliedToPmt(PurchHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYCrMAppliedToPmt()
    begin
        FCYDocAppliedToPmt(PurchHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvApplToPmtsAllOverWHTLimit()
    begin
        DocApplToPmtsAllOverWHTLimit(PurchHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrMApplToPmtsAllOverWHTLimit()
    begin
        DocApplToPmtsAllOverWHTLimit(PurchHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvApplToPmtsOneIsUnderWHTLimit()
    begin
        DocApplToPmtsOneIsUnderWHTLimit(PurchHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrMApplToPmtsOneIsUnderWHTLimit()
    begin
        DocApplToPmtsOneIsUnderWHTLimit(PurchHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvApplToBiggerPmt()
    begin
        DocApplToBiggerPmt(PurchHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrMApplToBiggerPmt()
    begin
        DocApplToBiggerPmt(PurchHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvApplToPmtAfterDiscDate()
    begin
        DocApplToPmtAfterDiscDate(PurchHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrMApplToPmtAfterDiscDate()
    begin
        DocApplToPmtAfterDiscDate(PurchHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvApplToTwoPmtsAfterDiscDate()
    begin
        DocApplToTwoPmtsAfterDiscDate(PurchHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrMApplToTwoPmtsAfterDiscDate()
    begin
        DocApplToTwoPmtsAfterDiscDate(PurchHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvApplToBiggerPmtAfterDiscDate()
    begin
        DocApplToBiggerPmtAfterDiscDate(PurchHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrMApplToBiggerPmtAfterDiscDate()
    begin
        DocApplToBiggerPmtAfterDiscDate(PurchHeader."Document Type"::"Credit Memo");
    end;

    local procedure JnlPmtLineApplIDTo2Of3PostedDoc(DocumentType: Enum "Purchase Document Type")
    var
        Vendor: Record Vendor;
        DocumentNo: array[2] of Code[20];
        PaymentNo: Code[20];
    begin
        // Bug 246185
        Initialize();
        CreateVendorWithPmtDisc(Vendor);

        PostTwoDocsWithPmtJnlLine(DocumentType, Vendor."No.", DocumentNo, PaymentNo);

        VerifyPaymentDiscountIsPosted(PaymentNo);
        VerifyWHTEntryIsRealizedCompletely(DocumentType, DocumentNo[1]);
        VerifyWHTEntryIsRealizedCompletely(DocumentType, DocumentNo[2]);
    end;

    local procedure JnlPmtLineApplToDocLine(DocumentType: Enum "Purchase Document Type"; ApplyToPostedDoc: Boolean)
    var
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        PaymentNo: Code[20];
    begin
        // Bug 265114
        Initialize();
        CreateVendorWithPmtDisc(Vendor);
        PostDocWithPmtJnlLine(DocumentType, Vendor."No.", ApplyToPostedDoc, DocumentNo, PaymentNo);

        VerifyPaymentDiscountIsPosted(PaymentNo);
        VerifyWHTEntryIsRealizedCompletely(DocumentType, DocumentNo);
    end;

    local procedure DocUnderWHTLimitAppliedToPmt(DocumentType: Enum "Purchase Document Type")
    var
        Vendor: Record Vendor;
        PostedDocumentNo: Code[20];
        PostedPmtDocNo: Code[20];
    begin
        Initialize();

        CreateVendorWithPmtDisc(Vendor);
        PostedDocumentNo := PostDocumentWithoutWHT(DocumentType, Vendor."No.");
        PostedPmtDocNo := ApplyPaymentToInvoice(Vendor."No.", PostedDocumentNo, -CalcDocumentAmount(PostedDocumentNo));

        VerifyPaymentDiscountIsPosted(PostedPmtDocNo);

        Assert.IsFalse(DoesWHTEntryExist(DocumentType, PostedDocumentNo), 'There must be no WHT Entry');
    end;

    local procedure DocAppliedToPmt(DocumentType: Enum "Purchase Document Type")
    var
        Vendor: Record Vendor;
        PostedDocumentNo: Code[20];
        PostedPmtDocNo: Code[20];
    begin
        Initialize();

        CreateVendorWithPmtDisc(Vendor);
        PostedDocumentNo := PostDocumentWithWHT(DocumentType, Vendor."No.");
        PostedPmtDocNo := ApplyPaymentToInvoice(Vendor."No.", PostedDocumentNo, -CalcDocumentAmount(PostedDocumentNo));

        VerifyPaymentDiscountIsPosted(PostedPmtDocNo);
        VerifyWHTEntryIsRealizedCompletely(DocumentType, PostedDocumentNo);
    end;

    local procedure UnapplyFCYDocAppliedToPmt(DocumentType: Enum "Purchase Document Type")
    var
        PostedDocumentNo: Code[20];
        PostedPmtDocNo: Code[20];
    begin
        // Bug 267064
        Initialize();

        ApplyFCYDocToPmt(DocumentType, PostedDocumentNo, PostedPmtDocNo);

        VerifyUnapply(PostedPmtDocNo);
    end;

    local procedure VerifyUnapply(PaymentDocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        with VendLedgEntry do begin
            SetRange("Document No.", PaymentDocNo);
            FindFirst();
            TestField(Open, false);

            LibraryERM.UnapplyVendorLedgerEntry(VendLedgEntry);

            Find();
            TestField(Open, true);
        end;
    end;

    local procedure FCYDocAppliedToPmt(DocumentType: Enum "Purchase Document Type")
    var
        PostedDocumentNo: Code[20];
        PostedPmtDocNo: Code[20];
    begin
        Initialize();

        ApplyFCYDocToPmt(DocumentType, PostedDocumentNo, PostedPmtDocNo);

        VerifyPaymentDiscountIsPosted(PostedPmtDocNo);
        VerifyWHTEntryIsRealizedCompletely(DocumentType, PostedDocumentNo);
    end;

    local procedure ApplyFCYDocToPmt(DocumentType: Enum "Purchase Document Type"; var PostedDocNo: Code[20]; var PaymentDocNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        CreateVendorWithPmtDisc(Vendor);
        SetCurrencyCodeOnVendor(Vendor);
        PostedDocNo := PostDocumentWithWHT(DocumentType, Vendor."No.");
        PaymentDocNo := ApplyPaymentToInvoice(Vendor."No.", PostedDocNo, -CalcDocumentAmount(PostedDocNo));
    end;

    local procedure DocApplToPmtsAllOverWHTLimit(DocumentType: Enum "Purchase Document Type")
    var
        Vendor: Record Vendor;
        PostedDocumentNo: Code[20];
        PostedPmtDocNo: Code[20];
        DocumentAmount: Decimal;
        FirstPmtAmount: Decimal;
    begin
        Initialize();

        CreateVendorWithPmtDisc(Vendor);
        PostedDocumentNo := PostDocumentWithWHT(DocumentType, Vendor."No.");
        DocumentAmount := CalcDocumentAmount(PostedDocumentNo);

        FirstPmtAmount := GetAmountOverMinWHT(PostedDocumentNo);
        ApplyPaymentToInvoice(Vendor."No.", PostedDocumentNo, FirstPmtAmount);

        PostedPmtDocNo := ApplyPaymentToInvoice(Vendor."No.", PostedDocumentNo, -DocumentAmount - FirstPmtAmount);

        VerifyPaymentDiscountIsPosted(PostedPmtDocNo);
        VerifyWHTEntryIsRealizedCompletely(DocumentType, PostedDocumentNo);
    end;

    local procedure DocApplToPmtsOneIsUnderWHTLimit(DocumentType: Enum "Purchase Document Type")
    var
        Vendor: Record Vendor;
        PostedDocumentNo: Code[20];
        PostedPmtDocNo: Code[20];
        DocumentAmount: Decimal;
        FirstPmtAmount: Decimal;
    begin
        Initialize();

        CreateVendorWithPmtDisc(Vendor);
        PostedDocumentNo := PostDocumentWithWHT(DocumentType, Vendor."No.");
        DocumentAmount := CalcDocumentAmount(PostedDocumentNo);

        FirstPmtAmount := GetAmountUnderMinWHT(PostedDocumentNo);

        ApplyPaymentToInvoice(Vendor."No.", PostedDocumentNo, FirstPmtAmount);

        PostedPmtDocNo := ApplyPaymentToInvoice(Vendor."No.", PostedDocumentNo, -DocumentAmount - FirstPmtAmount);

        VerifyPaymentDiscountIsPosted(PostedPmtDocNo);
        VerifyWHTEntryIsRealizedCompletely(DocumentType, PostedDocumentNo);
    end;

    local procedure DocApplToBiggerPmt(DocumentType: Enum "Purchase Document Type")
    var
        Vendor: Record Vendor;
        PostedDocumentNo: Code[20];
        PostedPmtDocNo: Code[20];
    begin
        Initialize();

        CreateVendorWithPmtDisc(Vendor);
        PostedDocumentNo := PostDocumentWithWHT(DocumentType, Vendor."No.");
        PostedPmtDocNo := ApplyPaymentToInvoice(Vendor."No.", PostedDocumentNo, GetAmountBiggerThanInvoice(PostedDocumentNo));

        VerifyPaymentDiscountIsPosted(PostedPmtDocNo);
        VerifyWHTEntryIsRealizedCompletely(DocumentType, PostedDocumentNo);
    end;

    local procedure DocApplToPmtAfterDiscDate(DocumentType: Enum "Purchase Document Type")
    var
        Vendor: Record Vendor;
        PostedDocumentNo: Code[20];
        PostedPmtDocNo: Code[20];
    begin
        Initialize();

        CreateVendorWithPmtDisc(Vendor);
        PostedDocumentNo := PostDocumentWithWHT(DocumentType, Vendor."No.");
        PostedPmtDocNo := ApplyPaymentToInvoiceAfterDiscDate(Vendor."No.", PostedDocumentNo, -CalcDocumentAmount(PostedDocumentNo));

        asserterror VerifyPaymentDiscountIsPosted(PostedPmtDocNo);
        asserterror VerifyWHTEntryIsRealizedCompletely(DocumentType, PostedDocumentNo);
        Assert.ExpectedError('Remaining Unrealized Amount must be equal to ''0''');
    end;

    local procedure DocApplToTwoPmtsAfterDiscDate(DocumentType: Enum "Gen. Journal Document Type")
    var
        Vendor: Record Vendor;
        PostedDocumentNo: Code[20];
        PostedPmtDocNo: Code[20];
        DocumentAmount: Decimal;
        FirstPmtAmount: Decimal;
    begin
        Initialize();

        CreateVendorWithPmtDisc(Vendor);
        PostedDocumentNo := PostDocumentWithWHT(DocumentType, Vendor."No.");
        DocumentAmount := CalcDocumentAmount(PostedDocumentNo);

        FirstPmtAmount := GetAmountUnderMinWHT(PostedDocumentNo);
        ApplyPaymentToInvoiceAfterDiscDate(Vendor."No.", PostedDocumentNo, FirstPmtAmount);

        PostedPmtDocNo := ApplyPaymentToInvoiceAfterDiscDate(Vendor."No.", PostedDocumentNo, -DocumentAmount);

        asserterror VerifyPaymentDiscountIsPosted(PostedPmtDocNo);
        VerifyWHTEntryIsRealizedCompletely(DocumentType, PostedDocumentNo);
    end;

    local procedure DocApplToBiggerPmtAfterDiscDate(DocumentType: Enum "Purchase Document Type")
    var
        Vendor: Record Vendor;
        PostedDocumentNo: Code[20];
        PostedPmtDocNo: Code[20];
    begin
        Initialize();

        CreateVendorWithPmtDisc(Vendor);
        PostedDocumentNo := PostDocumentWithWHT(DocumentType, Vendor."No.");
        PostedPmtDocNo := ApplyPaymentToInvoiceAfterDiscDate(Vendor."No.", PostedDocumentNo, GetAmountBiggerThanInvoice(PostedDocumentNo));

        asserterror VerifyPaymentDiscountIsPosted(PostedPmtDocNo);
        VerifyWHTEntryIsRealizedCompletely(DocumentType, PostedDocumentNo);
    end;

    local procedure PostDocumentWithoutWHT(DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]): Code[20]
    begin
        exit(PostDocument(DocumentType, VendorNo, false));
    end;

    local procedure PostDocumentWithWHT(DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]): Code[20]
    begin
        exit(PostDocument(DocumentType, VendorNo, true));
    end;

    local procedure PostDocument(DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; OverMinWHTAmount: Boolean): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        Amount: Decimal;
        MinWHTAmount: Decimal;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        SetVendorCrMemoNo(PurchaseHeader);
        LibraryERM.FindGLAccount(GLAccount);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        MinWHTAmount := GetWHTMinDocumentAmount(PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        if OverMinWHTAmount then
            Amount := 3 * MinWHTAmount + LibraryRandom.RandDec(100, 2)
        else
            Amount := Round(MinWHTAmount / 2);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure SetVendorCrMemoNo(var PurchaseHeader: Record "Purchase Header")
    begin
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then begin
            PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
            PurchaseHeader.Modify();
        end;
    end;

    local procedure ApplyPaymentToInvoice(VendorNo: Code[20]; PostedDocumentNo: Code[20]; PmtAmount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        PreparePaymentLine(VendorNo, PostedDocumentNo, PmtAmount, GenJournalLine);
        exit(PostGenJnlLine(GenJournalLine));
    end;

    local procedure ApplyPaymentToInvoiceAfterDiscDate(VendorNo: Code[20]; PostedDocumentNo: Code[20]; PmtAmount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        PreparePaymentLine(VendorNo, PostedDocumentNo, PmtAmount, GenJournalLine);
        Vendor.Get(VendorNo);
        GenJournalLine.Validate("Posting Date", GetDateAfterPmtDisc(Vendor."Payment Terms Code", GenJournalLine."Posting Date"));
        exit(PostGenJnlLine(GenJournalLine));
    end;

    local procedure PostTwoDocsWithPmtJnlLine(DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; var DocumentNo: array[2] of Code[20]; var PaymentDocNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocAmount: Decimal;
        PmtAmount: Decimal;
    begin
        PrepareJnlBatch(GenJournalLine);
        with GenJournalLine do begin
            "Account No." := VendorNo;

            PmtAmount := 0;
            DocAmount := -GetBiggerAmount(GetWHTMinDocumentAmount('', ''));
            if DocumentType = "Document Type"::"Credit Memo" then
                DocAmount := -DocAmount;

            DocumentNo[1] := PostDocJnlLine(GenJournalLine, DocumentType, DocAmount);
            PmtAmount -= Amount;

            PostDocJnlLine(GenJournalLine, DocumentType, GetBiggerAmount(Amount));

            DocumentNo[2] := PostDocJnlLine(GenJournalLine, DocumentType, GetBiggerAmount(Amount));
            PmtAmount -= Amount;

            SetApplyToIDToDocNo(VendorNo, DocumentType, DocumentNo[1]);
            SetApplyToIDToDocNo(VendorNo, DocumentType, DocumentNo[2]);

            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, "Journal Template Name", "Journal Batch Name",
              GetPmtDocumentType(DocumentType), "Account Type"::Vendor, "Account No.", PmtAmount);
            Validate("Applies-to ID", UserId);
            Modify(true);
            PaymentDocNo := "Document No.";
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostDocJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocAmount: Decimal): Code[20]
    var
        ApplToGenJnlLine: Record "Gen. Journal Line";
    begin
        with GenJournalLine do begin
            ApplToGenJnlLine := GenJournalLine;
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, "Journal Template Name", "Journal Batch Name",
              DocumentType, "Account Type"::Vendor, "Account No.", DocAmount);
            "External Document No." := "Document No.";
            "Applies-to Doc. Type" := ApplToGenJnlLine."Applies-to Doc. Type";
            "Applies-to Doc. No." := ApplToGenJnlLine."Applies-to Doc. No.";
            Modify(true);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
            exit("Document No.");
        end;
    end;

    local procedure SetApplyToIDToDocNo(VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        with VendLedgEntry do begin
            SetRange("Vendor No.", VendorNo);
            SetRange("Document Type", DocumentType);
            SetRange("Document No.", DocumentNo);
            FindFirst();

            LibraryERM.SetAppliestoIdVendor(VendLedgEntry);
        end;
    end;

    local procedure PostDocWithPmtJnlLine(DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; ApplyToPostedDoc: Boolean; var DocumentNo: Code[20]; var PaymentDocNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocAmount: Decimal;
    begin
        PrepareJnlBatch(GenJournalLine);
        with GenJournalLine do begin
            DocAmount := -GetBiggerAmount(GetWHTMinDocumentAmount('', ''));
            if DocumentType = "Document Type"::"Credit Memo" then
                DocAmount := -DocAmount;

            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, "Journal Template Name", "Journal Batch Name",
              DocumentType, "Account Type"::Vendor, VendorNo, DocAmount);
            "External Document No." := "Document No.";
            Modify(true);
            DocumentNo := "Document No.";
            if ApplyToPostedDoc then
                LibraryERM.PostGeneralJnlLine(GenJournalLine);

            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, "Journal Template Name", "Journal Batch Name",
              GetPmtDocumentType(DocumentType), "Account Type"::Vendor, VendorNo, -DocAmount);
            Validate("Applies-to Doc. Type", DocumentType);
            Validate("Applies-to Doc. No.", DocumentNo);
            Modify(true);
            PaymentDocNo := "Document No.";
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PrepareJnlBatch(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        FindPaymentBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        CopyBatchNameToLine(GenJournalBatch, GenJournalLine);
    end;

    local procedure CopyBatchNameToLine(GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        with GenJournalLine do begin
            "Journal Template Name" := GenJournalBatch."Journal Template Name";
            "Journal Batch Name" := GenJournalBatch.Name;
        end;
    end;

    local procedure PreparePaymentLine(VendorNo: Code[20]; PostedDocNo: Code[20]; PmtAmount: Decimal; var GenJournalLine: Record "Gen. Journal Line")
    var
        DocumentType: Enum "Gen. Journal Document Type";
    begin
        PrepareJnlBatch(GenJournalLine);
        DocumentType := GetDocumentType(PostedDocNo);
        with GenJournalLine do begin
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, "Journal Template Name", "Journal Batch Name",
              GetPmtDocumentType(DocumentType), "Account Type"::Vendor, VendorNo, PmtAmount);
            Validate("Applies-to Doc. Type", DocumentType);
            Validate("Applies-to Doc. No.", PostedDocNo);
        end;
    end;

    local procedure PostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"): Code[20]
    begin
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CalcDocumentAmount(PostedDocumentNo: Code[20]): Decimal
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        with VendLedgEntry do begin
            SetRange("Document No.", PostedDocumentNo);
            FindFirst();
            CalcFields("Remaining Amount");
            exit("Remaining Amount" - "Remaining Pmt. Disc. Possible");
        end;
    end;

    local procedure GetAmountBiggerThanInvoice(PostedDocumentNo: Code[20]): Decimal
    begin
        exit(-GetBiggerAmount(CalcDocumentAmount(PostedDocumentNo)));
    end;

    local procedure GetDateAfterPmtDisc(PaymentTermsCode: Code[10]; PostingDate: Date): Date
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(PaymentTermsCode);
        exit(CalcDate(PaymentTerms."Discount Date Calculation", PostingDate + 1));
    end;

    local procedure CreateVendorWithPmtDisc(var Vendor: Record Vendor)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        CreateVendorForWHT(Vendor);

        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify();

        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);
    end;

    local procedure CreateVendorForWHT(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(ABN, '');
        Vendor."Foreign Vend" := false;
    end;

    local procedure SetCurrencyCodeOnVendor(var Vendor: Record Vendor)
    var
        Currency: Record Currency;
    begin
        LibraryERM.FindCurrency(Currency);
        Vendor.Validate("Currency Code", Currency.Code);
        Vendor.Modify();
    end;

    local procedure FindPaymentBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        with GenJournalBatch do begin
            Reset();
            SetRange("Bal. Account Type", "Bal. Account Type"::"Bank Account");
            SetFilter("Bal. Account No.", '<>%1', '');
            FindFirst();
        end;
    end;

    local procedure GetWHTMinDocumentAmountByDocNo(DocumentNo: Code[20]): Decimal
    var
        WHTEntry: Record "WHT Entry";
        WHTMinDocumentAmount: Decimal;
    begin
        WHTEntry.SetRange("Document No.", DocumentNo);
        WHTEntry.FindFirst();
        WHTMinDocumentAmount := GetWHTMinDocumentAmount(WHTEntry."WHT Bus. Posting Group", WHTEntry."WHT Prod. Posting Group");
        if WHTEntry."Document Type" = WHTEntry."Document Type"::"Credit Memo" then
            WHTMinDocumentAmount := -WHTMinDocumentAmount;
        exit(WHTMinDocumentAmount);
    end;

    local procedure GetWHTMinDocumentAmount(WHTBusPostingGroup: Code[20]; WHTProdPostingGroup: Code[20]): Decimal
    var
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        WHTPostingSetup.Get(WHTBusPostingGroup, WHTProdPostingGroup);
        exit(WHTPostingSetup."WHT Minimum Invoice Amount");
    end;

    local procedure GetAmountOverMinWHT(DocumentNo: Code[20]): Decimal
    begin
        exit(GetBiggerAmount(GetWHTMinDocumentAmountByDocNo(DocumentNo)));
    end;

    local procedure GetAmountUnderMinWHT(DocumentNo: Code[20]): Decimal
    begin
        exit(Round(GetWHTMinDocumentAmountByDocNo(DocumentNo) / 2));
    end;

    local procedure DoesWHTEntryExist(DocumentType: Enum "Gen. Journal Document Type"; PostedDocNo: Code[20]): Boolean
    var
        WHTEntry: Record "WHT Entry";
    begin
        with WHTEntry do begin
            SetRange("Document Type", DocumentType);
            SetRange("Document No.", PostedDocNo);
            exit(not IsEmpty);
        end;
    end;

    local procedure VerifyWHTEntryIsRealizedCompletely(DocumentType: Enum "Gen. Journal Document Type"; PostedDocNo: Code[20])
    var
        WHTEntry: Record "WHT Entry";
        TotalRealizedBase: Decimal;
        TotalRealizedAmount: Decimal;
    begin
        with WHTEntry do begin
            SetRange("Document Type", DocumentType);
            SetRange("Document No.", PostedDocNo);
            FindFirst();

            TestField("Remaining Unrealized Amount", 0);
            TestField("Remaining Unrealized Base", 0);
            CalcRealizedWHTAmounts("Entry No.", TotalRealizedBase, TotalRealizedAmount);
            Assert.AreEqual("Unrealized Base", TotalRealizedBase, 'WHT Base should be realized completely.');
            Assert.AreEqual("Unrealized Amount", TotalRealizedAmount, 'WHT Amount should be realized completely.');
        end;
    end;

    local procedure CalcRealizedWHTAmounts(UnrealizedWHTEntryNo: Integer; var TotalRealizedBase: Decimal; var TotalRealizedAmount: Decimal)
    var
        PmtWHTEntry: Record "WHT Entry";
    begin
        with PmtWHTEntry do begin
            SetRange("Unrealized WHT Entry No.", UnrealizedWHTEntryNo);
            FindSet();
            repeat
                TotalRealizedBase += Base;
                TotalRealizedAmount += Amount;
            until Next() = 0;
        end;
    end;

    local procedure VerifyPaymentDiscountIsPosted(PostedPmtDocNo: Code[20])
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        with DtldVendLedgEntry do begin
            SetFilter("Document Type", '%1|%2', "Document Type"::Payment, "Document Type"::Refund);
            SetRange("Document No.", PostedPmtDocNo);
            SetRange("Entry Type", "Entry Type"::"Payment Discount");
            Assert.IsTrue(not IsEmpty, 'Payment Discount entry expected to be posted.');
        end;
    end;

    local procedure GetDocumentType(DocumentNo: Code[20]): Enum "Gen. Journal Document Type"
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetRange("Document No.", DocumentNo);
        VendLedgEntry.FindFirst();
        exit(VendLedgEntry."Document Type");
    end;

    local procedure GetPmtDocumentType(DocumentType: Enum "Gen. Journal Document Type"): Enum "Gen. Journal Document Type"
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        case DocumentType of
            VendLedgEntry."Document Type"::Invoice:
                exit(VendLedgEntry."Document Type"::Payment);
            VendLedgEntry."Document Type"::"Credit Memo":
                exit(VendLedgEntry."Document Type"::Refund);
        end;
    end;

    local procedure GetBiggerAmount(Amount: Decimal): Decimal
    begin
        exit(Round(Amount * 1.15));
    end;
}

