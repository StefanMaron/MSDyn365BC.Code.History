codeunit 147314 "Cartera Payables Installments"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cartera] [Payables] [Installments]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCarteraPayables: Codeunit "Library - Cartera Payables";
        LibraryPurchase: Codeunit "Library - Purchase";
        CountMismatchErr: Label 'Number of %1 does not match %2.', Comment = '%1=TableCaption;%2=FieldCaption';
        LibraryCarteraCommon: Codeunit "Library - Cartera Common";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        LocalCurrencyCode: Code[10];

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandler,PostApplicationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyCreditMemoToCarteraDocumentWithMultipleInstallments()
    var
        CreditMemoPurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        CreditMemoVendorLedgerEntry: Record "Vendor Ledger Entry";
        FirstInstallmentVendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        PurchInvLine: Record "Purch. Inv. Line";
        CreditMemoDocumentNo: Code[20];
        DocumentNo: Code[20];
        NoOfInstallments: Integer;
    begin
        Initialize();

        // Pre-Setup
        NoOfInstallments := 5;

        // Setup
        LibraryCarteraPayables.CreateCarteraVendorUseBillToCarteraPayment(Vendor, LocalCurrencyCode);
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, LocalCurrencyCode);
        LibraryCarteraPayables.SetPaymentTermsVatDistribution(Vendor."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);
        LibraryCarteraPayables.CreateMultipleInstallments(Vendor."Payment Terms Code", NoOfInstallments);
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Post-Setup
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchInvLine.SetRange(Type, PurchInvLine.Type::Item);
        PurchInvLine.FindFirst();
        LibraryCarteraPayables.FindOpenCarteraDocVendorLedgerEntries(FirstInstallmentVendorLedgerEntry,
          Vendor."No.", DocumentNo, FirstInstallmentVendorLedgerEntry."Document Situation"::Cartera,
          FirstInstallmentVendorLedgerEntry."Document Type"::Bill);
        FirstInstallmentVendorLedgerEntry.CalcFields("Original Amount");

        // Pre-Exercise
        CreateCreditMemoToCorrectInvoice(CreditMemoPurchaseHeader,
          Vendor."No.", DocumentNo, PurchInvLine."No.", 1, FirstInstallmentVendorLedgerEntry."Original Amount" / 2);
        CreditMemoDocumentNo := LibraryPurchase.PostPurchaseDocument(CreditMemoPurchaseHeader, true, true);
        LibraryERM.FindVendorLedgerEntry(CreditMemoVendorLedgerEntry,
          CreditMemoVendorLedgerEntry."Document Type"::"Credit Memo", CreditMemoDocumentNo);

        // Exercise
        ApplyCreditMemoToFirstInstallment(CreditMemoVendorLedgerEntry."Entry No.");

        // Verify
        VerifyRemainingAmountOnFirstInstallment(CreditMemoVendorLedgerEntry."Entry No.", FirstInstallmentVendorLedgerEntry."Entry No.");
        VerifyRemainingAmountOnCarteraDocOfFirstInstallment(FirstInstallmentVendorLedgerEntry."Entry No.", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandler,PostApplicationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyCrMemoToCarteraDocWithMultipleInstallmentsUnrealizedVAT()
    var
        CreditMemoPurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        CreditMemoVendorLedgerEntry: Record "Vendor Ledger Entry";
        FirstInstallmentVendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        PurchInvLine: Record "Purch. Inv. Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CreditMemoDocumentNo: Code[20];
        DocumentNo: Code[20];
        NoOfInstallments: Integer;
        SalesUnrealizedVATAccount: Code[20];
        PurchUnrealizedVATAccount: Code[20];
        TotalAmount: Decimal;
        InitialVATAmount: Decimal;
        CreditMemoVATAmount: Decimal;
        CreditMemoAmount: Decimal;
    begin
        Initialize();

        // Pre-Setup
        NoOfInstallments := 5;
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrealizedVATAccount, PurchUnrealizedVATAccount);

        // Setup
        LibraryCarteraPayables.CreateCarteraVendorUseBillToCarteraPayment(Vendor, LocalCurrencyCode);
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, LocalCurrencyCode);
        LibraryCarteraPayables.SetPaymentTermsVatDistribution(Vendor."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);
        LibraryCarteraPayables.CreateMultipleInstallments(Vendor."Payment Terms Code", NoOfInstallments);
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Post-Setup
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchInvLine.SetRange(Type, PurchInvLine.Type::Item);
        PurchInvLine.FindFirst();

        TotalAmount :=
          LibraryCarteraPayables.GetPostedPurchaseInvoiceAmount(
            Vendor."No.", DocumentNo, FirstInstallmentVendorLedgerEntry."Document Type"::Invoice);

        VATPostingSetup.Get(PurchInvLine."VAT Bus. Posting Group", PurchInvLine."VAT Prod. Posting Group");

        InitialVATAmount := -1 *
          Round(TotalAmount - TotalAmount * 100 / (VATPostingSetup."VAT %" + 100), LibraryERM.GetAmountRoundingPrecision);

        LibraryCarteraPayables.FindOpenCarteraDocVendorLedgerEntries(FirstInstallmentVendorLedgerEntry,
          Vendor."No.", DocumentNo, FirstInstallmentVendorLedgerEntry."Document Situation"::Cartera,
          FirstInstallmentVendorLedgerEntry."Document Type"::Bill);
        FirstInstallmentVendorLedgerEntry.CalcFields("Original Amount");

        // Pre-Exercise
        CreditMemoAmount := Round(FirstInstallmentVendorLedgerEntry."Original Amount" / 2, LibraryERM.GetAmountRoundingPrecision);
        CreateCreditMemoToCorrectInvoice(CreditMemoPurchaseHeader,
          Vendor."No.", DocumentNo, PurchInvLine."No.", 1, CreditMemoAmount);
        CreditMemoDocumentNo := LibraryPurchase.PostPurchaseDocument(CreditMemoPurchaseHeader, true, true);
        LibraryERM.FindVendorLedgerEntry(CreditMemoVendorLedgerEntry,
          CreditMemoVendorLedgerEntry."Document Type"::"Credit Memo", CreditMemoDocumentNo);

        // Exercise
        ApplyCreditMemoToFirstInstallment(CreditMemoVendorLedgerEntry."Entry No.");

        // Verify
        CreditMemoVATAmount := -1 * Round(CreditMemoAmount * VATPostingSetup."VAT %" / 100, LibraryERM.GetAmountRoundingPrecision);
        ValidateUnrVATGLEntriesAfterApplyingCreditMemo(PurchUnrealizedVATAccount, InitialVATAmount, CreditMemoVATAmount);
        ValidateUnrVATVendorEntriesAfterApplyingCreditMemo(Vendor."No.", CreditMemoVATAmount, -1 * CreditMemoAmount);
        VerifyRemainingAmountOnFirstInstallment(CreditMemoVendorLedgerEntry."Entry No.", FirstInstallmentVendorLedgerEntry."Entry No.");
        VerifyRemainingAmountOnCarteraDocOfFirstInstallment(FirstInstallmentVendorLedgerEntry."Entry No.", DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCarteraDocumentWithMultipleInstallments()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        NoOfInstallments: Integer;
        TotalAmount: Decimal;
    begin
        Initialize();

        // Pre-Setup
        NoOfInstallments := 5;

        // Setup
        LibraryCarteraPayables.CreateCarteraVendorUseBillToCarteraPayment(Vendor, LocalCurrencyCode);
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, LocalCurrencyCode);
        LibraryCarteraPayables.SetPaymentTermsVatDistribution(Vendor."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);
        LibraryCarteraPayables.CreateMultipleInstallments(Vendor."Payment Terms Code", NoOfInstallments);
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");

        // Exercise
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Pre-Verify
        TotalAmount :=
          LibraryCarteraPayables.GetPostedPurchaseInvoiceAmount(Vendor."No.", DocumentNo, VendorLedgerEntry."Document Type"::Invoice);

        // Verify
        ValidateInstallmentVendorLedgerEntries(Vendor."No.",
          DocumentNo, VendorLedgerEntry."Document Situation"::Cartera, TotalAmount, NoOfInstallments);
        ValidateInstallmentCarteraDocuments(Vendor."No.", DocumentNo, -TotalAmount, NoOfInstallments);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCarteraDocumentWithSingleInstallment()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        NoOfInstallments: Integer;
        TotalAmount: Decimal;
    begin
        Initialize();

        // Pre-Setup
        NoOfInstallments := 1;

        // Setup
        LibraryCarteraPayables.CreateCarteraVendorUseBillToCarteraPayment(Vendor, LocalCurrencyCode);
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, LocalCurrencyCode);
        LibraryCarteraPayables.SetPaymentTermsVatDistribution(Vendor."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);
        LibraryCarteraPayables.CreateMultipleInstallments(Vendor."Payment Terms Code", NoOfInstallments);
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");

        // Exercise
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Pre-Verify
        TotalAmount :=
          LibraryCarteraPayables.GetPostedPurchaseInvoiceAmount(Vendor."No.", DocumentNo, VendorLedgerEntry."Document Type"::Invoice);

        // Verify
        ValidateInstallmentVendorLedgerEntries(Vendor."No.",
          DocumentNo, VendorLedgerEntry."Document Situation"::Cartera, TotalAmount, NoOfInstallments);
        ValidateInstallmentCarteraDocuments(Vendor."No.", DocumentNo, -TotalAmount, NoOfInstallments);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCarteraDocumentWithInstallmentsAndUnrealizedVAT()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        NoOfInstallments: Integer;
        TotalAmount: Decimal;
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
    begin
        Initialize();

        // Pre-Setup
        NoOfInstallments := 1;

        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);

        // Setup
        LibraryCarteraPayables.CreateCarteraVendorForUnrealizedVAT(Vendor, LocalCurrencyCode);
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, LocalCurrencyCode);
        LibraryCarteraPayables.SetPaymentTermsVatDistribution(Vendor."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);
        LibraryCarteraPayables.CreateMultipleInstallments(Vendor."Payment Terms Code", NoOfInstallments);
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");

        // Remove the line discount - without it we would get more GL/Lines
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.ModifyAll(PurchaseLine."Line Discount %", 0, true);
        PurchaseLine.ModifyAll(PurchaseLine."Line Discount Amount", 0, true);

        // Exercise
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Pre-Verify
        TotalAmount :=
          LibraryCarteraPayables.GetPostedPurchaseInvoiceAmount(Vendor."No.", DocumentNo, VendorLedgerEntry."Document Type"::Invoice);

        // Verify
        LibraryCarteraPayables.ValidatePostedInvoiceUnrVATGLEntries(DocumentNo, PurchUnrVATAccount, -TotalAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotPostDocumentWithMultipleCarteraInstallmentsAndUnrealizedVAT()
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        NoOfInstallments: Integer;
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
    begin
        Initialize();

        // Pre-Setup
        NoOfInstallments := 5;

        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);

        // Setup
        LibraryCarteraPayables.CreateCarteraVendorForUnrealizedVAT(Vendor, LocalCurrencyCode);
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, LocalCurrencyCode);
        LibraryCarteraPayables.SetPaymentTermsVatDistribution(Vendor."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);
        LibraryCarteraPayables.CreateMultipleInstallments(Vendor."Payment Terms Code", NoOfInstallments);
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");

        // Exercise
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify
        Assert.ExpectedError('No. of Installments must be 1 if Invoices to Cartera is True in Payment Method');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCarteraPurchaseDocumentWithMultipleInstallmentsSmallAmount()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        NoOfInstallments: Integer;
        TotalAmount: Decimal;
    begin
        // [SCENARIO 307483] Create cartera documents when Purchase Document with small amount has Payment Terms of multiple installments
        Initialize();

        // [GIVEN] Purchase Invoice has Payment Method with Create Bills = Yes and Payment Terms with 5 installments
        NoOfInstallments := LibraryRandom.RandIntInRange(2, 5);
        LibraryCarteraPayables.CreateCarteraVendorUseBillToCarteraPayment(Vendor, LocalCurrencyCode);
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, LocalCurrencyCode);
        LibraryCarteraPayables.SetPaymentTermsVatDistribution(Vendor."Payment Terms Code",
          PaymentTerms."VAT distribution"::Proportional);
        LibraryCarteraPayables.CreateMultipleInstallments(Vendor."Payment Terms Code", NoOfInstallments);
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");

        // [GIVEN] Amount of the invoice is 0.01
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate(Quantity, 1);
        PurchaseLine.Validate("Direct Unit Cost", 0.01);
        PurchaseLine.Modify();

        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] One Vendor Ledger Entry with "Document Situation" = Cartera is created for amount = 0.01
        // [THEN] One Cartera Document is created for amount = 0.01 and BillNo = 1
        TotalAmount :=
          LibraryCarteraPayables.GetPostedPurchaseInvoiceAmount(Vendor."No.", DocumentNo, VendorLedgerEntry."Document Type"::Invoice);
        ValidateInstallmentVendorLedgerEntries(Vendor."No.",
          DocumentNo, VendorLedgerEntry."Document Situation"::Cartera, TotalAmount, 1);
        ValidateInstallmentCarteraDocuments(Vendor."No.", DocumentNo, -TotalAmount, 1);
    end;

    [Test]
    procedure VATIsFullyRealizedAfterSevPmtToBillApplicationsForSevInstallments()
    var
        PaymentMethod: Record "Payment Method";
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
        SalesUnrVATAccount: Code[20];
        PurchUnrVATAccount: Code[20];
    begin
        // [FEATURE] [Unrealized VAT]
        // [SCENARIO 403927] Purchase invoice unrealized VAT is fully realized after several payment to Bill applications
        // [SCENARIO 403927] in case of several installments
        Initialize();

        // [GIVEN] Unrealized VAT setup, payment term with 2 installments
        LibraryCarteraCommon.SetupUnrealizedVAT(SalesUnrVATAccount, PurchUnrVATAccount);
        LibraryCarteraPayables.CreateCarteraVendorForUnrealizedVAT(Vendor, LocalCurrencyCode);
        LibraryCarteraPayables.CreateVendorBankAccount(Vendor, LocalCurrencyCode);
        LibraryCarteraPayables.SetPaymentTermsVatDistribution(
          Vendor."Payment Terms Code", PaymentTerms."VAT distribution"::Proportional);
        LibraryCarteraPayables.CreateMultipleInstallments(Vendor."Payment Terms Code", 2);

        // [GIVEN] Posted purchase invoice with 2 opened Bills
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, true, false);
        LibraryCarteraPayables.CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");
        PurchaseHeader.Validate("Payment Method Code", PaymentMethod.Code);
        PurchaseHeader.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        VATEntry.TestField("Unrealized Base");
        VATEntry.TestField("Unrealized Amount");
        VATEntry.TestField("Remaining Unrealized Base", VATEntry."Unrealized Base");
        VATEntry.TestField("Remaining Unrealized Amount", VATEntry."Unrealized Amount");

        // [GIVEN] Apply and post the first Bill
        ApplyPostFirstOpenBill(Vendor."No.", DocumentNo);

        // [WHEN] Apply and post the second Bill
        ApplyPostFirstOpenBill(Vendor."No.", DocumentNo);

        // [THEN] Original document unrealized VAT is fully realized
        VATEntry.Find();
        VATEntry.TestField("Remaining Unrealized Base", 0);
        VATEntry.TestField("Remaining Unrealized Amount", 0);
    end;

    local procedure Initialize()
    begin
        LibraryCarteraCommon.RevertUnrealizedVATPostingSetup;
        LocalCurrencyCode := '';
    end;

    local procedure CreateCreditMemoToCorrectInvoice(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; CorrectedInvoiceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; UnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseHeader.Validate("Corrected Invoice No.", CorrectedInvoiceNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", CorrectedInvoiceNo);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", -1 * UnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure ApplyCreditMemoToFirstInstallment(EntryNo: Integer)
    var
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        VendorLedgerEntries.OpenEdit;
        VendorLedgerEntries.GotoKey(EntryNo);
        VendorLedgerEntries.ActionApplyEntries.Invoke;
    end;

    local procedure ApplyPostFirstOpenBill(VendorNo: Code[20]; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange(Open, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Bill, DocumentNo);
        VendorLedgerEntry.CalcFields(Amount);
        VendorLedgerEntry.Validate("Applies-to ID", LibraryUtility.GenerateGUID());
        VendorLedgerEntry.Validate("Amount to Apply", VendorLedgerEntry.Amount);
        VendorLedgerEntry.Modify(true);

        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorNo, -VendorLedgerEntry.Amount);
        GenJournalLine.Validate("Applies-to ID", VendorLedgerEntry."Applies-to ID");
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure VerifyRemainingAmountOnFirstInstallment(ApplyingVendorLedgerEntryNo: Integer; AppliedToVendorLedgerEntryNo: Integer)
    var
        AppliedToVendorLedgerEntry: Record "Vendor Ledger Entry";
        ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        ApplyingVendorLedgerEntry.Get(ApplyingVendorLedgerEntryNo);
        ApplyingVendorLedgerEntry.TestField(Open, false);
        ApplyingVendorLedgerEntry.CalcFields("Remaining Amount");
        ApplyingVendorLedgerEntry.TestField("Remaining Amount", 0);

        AppliedToVendorLedgerEntry.Get(AppliedToVendorLedgerEntryNo);
        AppliedToVendorLedgerEntry.TestField(Open, true);
        AppliedToVendorLedgerEntry.CalcFields("Original Amount", "Remaining Amount");
        Assert.IsTrue(AppliedToVendorLedgerEntry."Remaining Amount" < 0, '');
        Assert.IsTrue(AppliedToVendorLedgerEntry."Remaining Amount" > AppliedToVendorLedgerEntry."Original Amount", '');
    end;

    local procedure VerifyRemainingAmountOnCarteraDocOfFirstInstallment(AppliedToVendorLedgerEntryNo: Integer; DocumentNo: Code[20])
    var
        AppliedToVendorLedgerEntry: Record "Vendor Ledger Entry";
        CarteraDoc: Record "Cartera Doc.";
        PayablesCarteraDocs: TestPage "Payables Cartera Docs";
    begin
        AppliedToVendorLedgerEntry.Get(AppliedToVendorLedgerEntryNo);
        AppliedToVendorLedgerEntry.CalcFields("Remaining Amount");

        CarteraDoc.SetRange(Type, CarteraDoc.Type::Payable);
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("No.", '1');
        CarteraDoc.FindFirst();

        PayablesCarteraDocs.OpenView;
        PayablesCarteraDocs.GotoRecord(CarteraDoc);
        PayablesCarteraDocs."Remaining Amount".AssertEquals(-1 * AppliedToVendorLedgerEntry."Remaining Amount");
    end;

    local procedure ValidateInstallmentCarteraDocuments(AccountNo: Code[20]; DocumentNo: Code[20]; TotalAmount: Decimal; NoOfInstallments: Integer)
    var
        CarteraDoc: Record "Cartera Doc.";
        PaymentTerms: Record "Payment Terms";
        Index: Integer;
        CarteraDocsTotalAmount: Decimal;
    begin
        LibraryCarteraPayables.FindCarteraDocs(CarteraDoc, AccountNo, DocumentNo);
        Assert.AreEqual(NoOfInstallments, CarteraDoc.Count,
          StrSubstNo(CountMismatchErr, CarteraDoc.TableCaption(), PaymentTerms.FieldCaption("No. of Installments")));

        CarteraDocsTotalAmount := 0;

        repeat
            Index += 1;
            CarteraDoc.TestField("No.", Format(Index));
            CarteraDoc.TestField(Description, StrSubstNo('%1 %2/%3', CarteraDoc."Document Type", DocumentNo, Index));
            Assert.AreNearlyEqual(TotalAmount / NoOfInstallments, CarteraDoc."Remaining Amount", 0.1, 'Wrong amount on the line');
            CarteraDocsTotalAmount += CarteraDoc."Remaining Amount"
        until CarteraDoc.Next() = 0;

        Assert.AreEqual(TotalAmount, CarteraDocsTotalAmount, 'There was a rounding error');
    end;

    local procedure ValidateInstallmentVendorLedgerEntries(VendorNo: Code[20]; DocumentNo: Code[20]; DocumentSituation: Option; TotalAmount: Decimal; NoOfInstallments: Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        Index: Integer;
        VendorLedgerTotalAmount: Decimal;
    begin
        LibraryCarteraPayables.FindOpenCarteraDocVendorLedgerEntries(VendorLedgerEntry,
          VendorNo, DocumentNo, DocumentSituation, VendorLedgerEntry."Document Type"::Bill);
        Assert.AreEqual(NoOfInstallments, VendorLedgerEntry.Count,
          StrSubstNo(CountMismatchErr, VendorLedgerEntry.TableCaption(), PaymentTerms.FieldCaption("No. of Installments")));

        VendorLedgerTotalAmount := 0;

        repeat
            Index += 1;
            VendorLedgerEntry.TestField("Bill No.", Format(Index));
            VendorLedgerEntry.TestField(Description, StrSubstNo('%1 %2/%3', VendorLedgerEntry."Document Type", DocumentNo, Index));
            VendorLedgerEntry.CalcFields(Amount);
            Assert.AreNearlyEqual(TotalAmount / NoOfInstallments, VendorLedgerEntry.Amount, 0.1, 'Wrong amount on Vendor Ledger Entry');
            VendorLedgerTotalAmount += VendorLedgerEntry.Amount;
        until VendorLedgerEntry.Next() = 0;

        Assert.AreEqual(TotalAmount, VendorLedgerTotalAmount, 'Amounts do not match, there is a rounding error');
    end;

    local procedure ValidateUnrVATGLEntriesAfterApplyingCreditMemo(AccountNo: Code[20]; InitialVATAmount: Decimal; CreditMemoVATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.Find('-');
        Assert.AreEqual(InitialVATAmount, GLEntry."Debit Amount", 'Wrong amount for the Initial VAT Amount');

        GLEntry.Next();
        Assert.AreEqual(CreditMemoVATAmount, GLEntry."Credit Amount", 'Wrong amount for Credit Memo Amount');

        GLEntry.Next();
        Assert.AreEqual(CreditMemoVATAmount, GLEntry."Credit Amount", 'Wrong amount for Credit Memo Amount');

        GLEntry.Next();
        Assert.AreEqual(CreditMemoVATAmount, GLEntry."Debit Amount", 'Wrong amount for Applied Credit Memo Amount');

        Assert.IsTrue(GLEntry.Next() = 0, 'Too many G/L entries were found after posting and applying a Credit Memo');
    end;

    local procedure ValidateUnrVATVendorEntriesAfterApplyingCreditMemo(VendorNo: Code[20]; CreditMemoVATAmount: Decimal; CreditMemoBaseAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", VendorNo);

        VATEntry.Find('-');
        Assert.AreEqual(0, VATEntry.Amount, 'Wrong value for the VAT entry for Amount on Invoice');
        Assert.AreEqual(0, VATEntry.Base, 'Wrong value for the VAT entry for Base on Invoice');
        Assert.AreEqual(VATEntry."Document Type"::Invoice, VATEntry."Document Type", 'Wrong document type on the line');

        VATEntry.Next();
        Assert.AreEqual(0, VATEntry.Amount, 'Wrong value for the VAT entry for Amount on Credit Memo');
        Assert.AreEqual(0, VATEntry.Base, 'Wrong value for the VAT entry for Base on Credit Memo');
        Assert.AreEqual(VATEntry."Document Type"::"Credit Memo", VATEntry."Document Type", 'Wrong document type on the line');

        VATEntry.Next();
        Assert.AreEqual(CreditMemoVATAmount, VATEntry.Amount, 'Wrong value for the VAT entry for Amount on Credit Memo');
        Assert.AreEqual(CreditMemoBaseAmount, VATEntry.Base, 'Wrong value for the VAT entry for Base on Credit Memo');
        Assert.AreEqual(VATEntry."Document Type"::"Credit Memo", VATEntry."Document Type", 'Wrong document type on the line');

        VATEntry.Next();
        Assert.AreEqual(-1 * CreditMemoVATAmount, VATEntry.Amount, 'Wrong value for the VAT entry for Amount on Credit Memo');
        Assert.AreEqual(-1 * CreditMemoBaseAmount, VATEntry.Base, 'Wrong value for the VAT entry for Base on Credit Memo');
        Assert.AreEqual(VATEntry."Document Type"::"Credit Memo", VATEntry."Document Type", 'Wrong document type on the line');

        Assert.IsTrue(VATEntry.Next() = 0, 'Too many VAT Entries were found after posting and applying a Credit Memo');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke;
        ApplyVendorEntries.ActionPostApplication.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationPageHandler(var PostApplication: TestPage "Post Application")
    begin
        PostApplication.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;
}

