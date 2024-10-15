codeunit 147125 "ERM VAT Invoices Journal"
{
    //     TEST FUNCTION NAME                  TFS ID
    // 1. IssuedFacturesInSamePeriod           341218
    // 2. IssuedFacturesInNextPeriod           341220
    // 3. ReceivedFacturesInSamePeriod         341217
    // 4. ReceivedFacturesInNextPeriod         341033

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryPurch: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        ReportType: Option Received,Issued;
        IncorrectEntryCountErr: Label 'Incorrect count of entries in table %1.';
        WrongFieldValueErr: Label 'Wrong value in field %1 in table %2.';

    [Test]
    [Scope('OnPrem')]
    procedure IssuedFacturesInSamePeriod()
    begin
        IssuedFactures(CalcDate('<CM-1D>', WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IssuedFacturesInNextPeriod()
    begin
        IssuedFactures(CalcDate('<+3M>', WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedFacturesInSamePeriod()
    begin
        ReceivedFactures(CalcDate('<CM-1D>', WorkDate()), CalcDate('<CM-1D>', WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivedFacturesInNextPeriod()
    begin
        ReceivedFactures(CalcDate('<CM-1D>', WorkDate()), CalcDate('<+3M>', WorkDate()));
    end;

    local procedure IssuedFactures(NewDate: Date)
    var
        PurchHeader: Record "Purchase Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        InvNo: Code[20];
        CrMemoNo: Code[20];
        ShowCorrection: Boolean;
        Amount: Decimal;
    begin
        GLAccountNo := CreateVendorAndGLAcount(VendorNo);
        Amount := LibraryRandom.RandDec(100, 2);
        CreateInvoice(PurchHeader, WorkDate(), VendorNo, GLAccountNo, Amount, false, '', '');
        UpdateVATInvoiceInfo(PurchHeader, Format(WorkDate()), WorkDate(), WorkDate());
        InvNo := PostPurchDoc(PurchHeader);

        CreateCrMemo(PurchHeader, NewDate, VendorNo, GLAccountNo, Round(Amount / 3, 1), true, InvNo);
        UpdateVATInvoiceInfo(PurchHeader, Format(NewDate), NewDate, NewDate);
        UpdateInclInSalesVATLedger(PurchHeader, true);
        CrMemoNo := PostPurchDoc(PurchHeader);

        for ShowCorrection := false to true do begin
            // pass 1 for entry count
            VerifyVendVATListEntries(
              VendorNo, ReportType::Issued, NewDate, ShowCorrection, 1, VendLedgEntry."Document Type"::"Credit Memo", CrMemoNo);
            VerifyVendVATListEntries(
              VendorNo, ReportType::Received, NewDate, ShowCorrection, 1, VendLedgEntry."Document Type"::Invoice, InvNo);
        end;
    end;

    local procedure ReceivedFactures(CrMemoDate: Date; InvDate: Date)
    var
        PurchHeader: Record "Purchase Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        GLAccountNo: Code[20];
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        Amount: Decimal;
    begin
        GLAccountNo := CreateVendorAndGLAcount(VendorNo);
        Amount := LibraryRandom.RandDec(100, 2);
        CreateInvoice(PurchHeader, WorkDate(), VendorNo, GLAccountNo, Amount, false, '', '');
        UpdateVATInvoiceInfo(PurchHeader, Format(WorkDate()), WorkDate(), WorkDate());
        PostedDocNo := PostPurchDoc(PurchHeader);

        CreateCrMemo(PurchHeader, CrMemoDate, VendorNo, GLAccountNo, Amount, false, '');
        UpdateVATInvoiceInfo(PurchHeader, Format(CrMemoDate), CrMemoDate, CrMemoDate);

        CreateInvoice(PurchHeader, InvDate, VendorNo, GLAccountNo, Amount, true, PostedDocNo, '1');
        UpdateVATInvoiceInfo(PurchHeader, Format(InvDate), InvDate, InvDate);
        PostedDocNo := PostPurchDoc(PurchHeader);

        VerifyVendVATListEntries(
          VendorNo, ReportType::Issued, InvDate, false, 0, "Gen. Journal document Type"::" ", '');
        VerifyVendVATListEntries(
          VendorNo, ReportType::Received, InvDate, false, 2, VendLedgEntry."Document Type"::Invoice, PostedDocNo);
    end;

    local procedure CreateInvoice(var PurchHeader: Record "Purchase Header"; PostingDate: Date; VendorNo: Code[20]; GLAccountNo: Code[20]; DirectUnitCost: Decimal; IsCorrInvoice: Boolean; CorrDocNo: Code[20]; RevisionNo: Code[20])
    begin
        CreatePurchDoc(
          PurchHeader, PurchHeader."Document Type"::Invoice,
          PostingDate, VendorNo);
        if IsCorrInvoice then
            UpdateRevisionInfo(PurchHeader, PurchHeader."Corrected Doc. Type"::Invoice, CorrDocNo, RevisionNo);
        CreatePurchLine(PurchHeader, GLAccountNo, DirectUnitCost);
    end;

    local procedure CreateCrMemo(var PurchHeader: Record "Purchase Header"; PostingDate: Date; VendorNo: Code[20]; GLAccountNo: Code[20]; DirectUnitCost: Decimal; IsCorrInvoice: Boolean; CorrDocNo: Code[20])
    begin
        CreatePurchDoc(
          PurchHeader, PurchHeader."Document Type"::"Credit Memo",
          PostingDate, VendorNo);
        if IsCorrInvoice then
            UpdateCorrectionInfo(
              PurchHeader, PurchHeader."Corrective Doc. Type"::Correction, PurchHeader."Corrected Doc. Type"::Invoice, CorrDocNo);
        CreatePurchLine(PurchHeader, GLAccountNo, DirectUnitCost);
    end;

    local procedure CreatePurchDoc(var PurchHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type"; PostingDate: Date; VendorNo: Code[20])
    begin
        with PurchHeader do begin
            LibraryPurch.CreatePurchHeader(PurchHeader, DocType, VendorNo);
            SetHideValidationDialog(true);
            Validate("Posting Date", PostingDate);
            Validate("Prices Including VAT", true);
            Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
            Modify(true);
        end;
    end;

    local procedure CreatePurchLine(PurchHeader: Record "Purchase Header"; GLAccountNo: Code[20]; DirectunitCost: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        with PurchLine do begin
            LibraryPurch.CreatePurchaseLine(PurchLine, PurchHeader, Type::"G/L Account", GLAccountNo, 1);
            Validate("Direct Unit Cost", DirectunitCost);
            Modify();
        end;
    end;

    local procedure CreateVendorAndGLAcount(var VendorNo: Code[20]): Code[20]
    begin
        VendorNo := LibraryPurch.CreateVendorNo();
        exit(LibraryERM.CreateGLAccountWithPurchSetup());
    end;

    local procedure PostPurchDoc(PurchHeader: Record "Purchase Header"): Code[20]
    begin
        exit(LibraryPurch.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure UpdateCorrectionInfo(var PurchHeader: Record "Purchase Header"; CorrType: Option; CorrDocType: Option; CorrDocNo: Code[20])
    begin
        with PurchHeader do begin
            Validate("Corrective Document", true);
            Validate("Corrective Doc. Type", CorrType);
            Validate("Corrected Doc. Type", CorrDocType);
            Validate("Corrected Doc. No.", CorrDocNo);
            Modify(true);
        end;
    end;

    local procedure UpdateRevisionInfo(var PurchHeader: Record "Purchase Header"; CorrDocType: Option; CorrDocNo: Code[20]; RevisionNo: Code[20])
    begin
        with PurchHeader do begin
            UpdateCorrectionInfo(PurchHeader, "Corrective Doc. Type"::Revision, CorrDocType, CorrDocNo);
            Validate("Revision No.", RevisionNo);
            Modify(true);
        end;
    end;

    local procedure UpdateVATInvoiceInfo(var PurchHeader: Record "Purchase Header"; VATInvNo: Code[20]; VATInvDate: Date; VATInvRcvdDate: Date)
    begin
        with PurchHeader do begin
            Validate("Vendor VAT Invoice No.", VATInvNo);
            Validate("Vendor VAT Invoice Date", VATInvDate);
            Validate("Vendor VAT Invoice Rcvd Date", VATInvRcvdDate);
            Modify(true);
        end;
    end;

    local procedure UpdateInclInSalesVATLedger(var PurchHeader: Record "Purchase Header"; IsIncludeInSalesVATLedger: Boolean)
    begin
        with PurchHeader do begin
            Validate("Include In Sales VAT Ledger", IsIncludeInSalesVATLedger);
            Modify(true);
        end;
    end;

    local procedure VerifyVendVATListEntries(VendNo: Code[20]; ReportType: Option Received,Issued; EndDate: Date; ShowCorrection: Boolean; EntriesCount: Integer; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        Vendor: Record Vendor;
        Period: Record Date;
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        VATInvoiceJournalMgt: Codeunit "VAT Invoice Journal Management";
    begin
        Vendor.SetFilter("No.", VendNo);
        Period."Period Start" := WorkDate();
        Period."Period End" := EndDate;
        with TempVendorLedgerEntry do begin
            VATInvoiceJournalMgt.GetVendVATList(
              TempVendorLedgerEntry, Vendor, ReportType, Period, ShowCorrection);
            Assert.AreEqual(
              EntriesCount, Count, StrSubstNo(IncorrectEntryCountErr, TableCaption));
            if EntriesCount = 0 then
                exit;
            Assert.AreEqual(
              DocType, "Document Type", StrSubstNo(WrongFieldValueErr, FieldCaption("Document Type"), TableCaption));
            Assert.AreEqual(
              DocNo, "Document No.", StrSubstNo(WrongFieldValueErr, FieldCaption("Document No."), TableCaption));
        end;
    end;
}

