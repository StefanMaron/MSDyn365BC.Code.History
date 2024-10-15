#pragma warning disable AL0432
codeunit 148054 "VAT Date CZL"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        DocumentType: Enum "Gen. Journal Document Type";
        AccountType: Enum "Gen. Journal Account Type";
        SalesDocumentType: Enum "Sales Document Type";
        PurchaseDocumentType: Enum "Purchase Document Type";
        ServiceDocumentType: Enum "Service Document Type";
        isInitialized: Boolean;

    local procedure Initialize();
    var
        UserSetup: Record "User Setup";
    begin
        LibraryRandom.Init();
        if isInitialized then
            exit;

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Use VAT Date" := false;
        GeneralLedgerSetup."Use VAT Date CZL" := true;
        GeneralLedgerSetup."Allow VAT Posting From" := 0D;
        GeneralLedgerSetup."Allow VAT Posting From CZL" := 0D;
        GeneralLedgerSetup."Allow VAT Posting To" := 0D;
        GeneralLedgerSetup."Allow VAT Posting To CZL" := 0D;
        GeneralLedgerSetup.Modify();

        UserSetup.ModifyAll(UserSetup."Allow VAT Posting From CZL", 0D);
        UserSetup.ModifyAll(UserSetup."Allow VAT Posting To CZL", 0D);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Order Nos." := LibraryERM.CreateNoSeriesCode();
        SalesReceivablesSetup."Default VAT Date" := SalesReceivablesSetup."Default VAT Date"::Blank;
        SalesReceivablesSetup."Default VAT Date CZL" := SalesReceivablesSetup."Default VAT Date CZL"::Blank;
        SalesReceivablesSetup.Modify();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Order Nos." := LibraryERM.CreateNoSeriesCode();
        PurchasesPayablesSetup."Default VAT Date" := PurchasesPayablesSetup."Default VAT Date"::Blank;
        PurchasesPayablesSetup."Default VAT Date CZL" := PurchasesPayablesSetup."Default VAT Date CZL"::Blank;
        PurchasesPayablesSetup.Modify();

        ServiceMgtSetup.Get();
        ServiceMgtSetup."Service Order Nos." := LibraryERM.CreateNoSeriesCode();
        ServiceMgtSetup."Default VAT Date" := ServiceMgtSetup."Default VAT Date"::Blank;
        ServiceMgtSetup."Default VAT Date CZL" := ServiceMgtSetup."Default VAT Date CZL"::Blank;
        ServiceMgtSetup.Modify();

        isInitialized := true;
        Commit();
    end;

    [Test]
    procedure SalesHeaderWithBlankVatDate()
    begin
        // [FEATURE] VAT Date
        Initialize();

        // [GIVEN] Sales Setup with Blank VAT Date
        SalesReceivablesSetup."Default VAT Date CZL" := SalesReceivablesSetup."Default VAT Date CZL"::Blank;
        SalesReceivablesSetup.Modify();

        // [GIVEN] New Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesDocumentType::Order, LibrarySales.CreateCustomerNo());

        // [WHEN] Validate Posting Date
        SalesHeader.Validate("Posting Date", LibraryRandom.RandDate(30));

        // [THEN] VAT Date is blank
        Assert.AreEqual(0D, SalesHeader."VAT Date CZL", SalesHeader.FieldCaption(SalesHeader."VAT Date CZL"));
    end;

    [Test]
    procedure SalesHeaderWithPostingVatDate()
    begin
        // [FEATURE] VAT Date
        Initialize();

        // [GIVEN] Sales Setup with Blank VAT Date
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Default VAT Date CZL" := SalesReceivablesSetup."Default VAT Date CZL"::"Posting Date";
        SalesReceivablesSetup.Modify();

        // [WHEN] Validate Posting Date
        SalesHeader.Validate("Posting Date", LibraryRandom.RandDate(30));

        // [THEN] VAT Date is Posting Date
        Assert.AreEqual(SalesHeader."Posting Date", SalesHeader."VAT Date CZL", SalesHeader.FieldCaption(SalesHeader."VAT Date CZL"));
    end;

    [Test]
    procedure PurchaseHeaderWithBlankVatDate()
    begin
        // [FEATURE] VAT Date
        Initialize();

        // [GIVEN] Purchase Setup with Blank VAT Date
        PurchasesPayablesSetup."Default VAT Date CZL" := PurchasesPayablesSetup."Default VAT Date CZL"::Blank;
        PurchasesPayablesSetup.Modify();

        // [GIVEN] New Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseDocumentType::Order, LibraryPurchase.CreateVendorNo());

        // [WHEN] Validate Posting Date
        PurchaseHeader.Validate("Posting Date", LibraryRandom.RandDate(30));

        // [THEN] VAT Date is blank
        Assert.AreEqual(0D, PurchaseHeader."VAT Date CZL", PurchaseHeader.FieldCaption(PurchaseHeader."VAT Date CZL"));
    end;

    [Test]
    procedure PurchaseHeaderWithPostingVatDate()
    begin
        // [FEATURE] VAT Date
        Initialize();

        // [GIVEN] Purchase Setup with Blank VAT Date
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Default VAT Date CZL" := PurchasesPayablesSetup."Default VAT Date CZL"::"Posting Date";
        PurchasesPayablesSetup.Modify();

        // [WHEN] Validate Posting Date
        PurchaseHeader.Validate("Posting Date", LibraryRandom.RandDate(30));

        // [THEN] VAT Date is Posting Date
        Assert.AreEqual(PurchaseHeader."Posting Date", PurchaseHeader."VAT Date CZL", PurchaseHeader.FieldCaption(PurchaseHeader."VAT Date CZL"));
    end;

    [Test]
    procedure ServiceHeaderWithBlankVatDate()
    begin
        // [FEATURE] VAT Date
        Initialize();

        // [GIVEN] Sales Setup with Blank VAT Date
        ServiceMgtSetup."Default VAT Date CZL" := ServiceMgtSetup."Default VAT Date CZL"::Blank;
        ServiceMgtSetup.Modify();

        // [GIVEN] New Service Order
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceDocumentType::Order, LibrarySales.CreateCustomerNo());

        // [WHEN] Validate Posting Date
        ServiceHeader.Validate("Posting Date", LibraryRandom.RandDate(30));

        // [THEN] VAT Date is blank
        Assert.AreEqual(0D, ServiceHeader."VAT Date CZL", ServiceHeader.FieldCaption(ServiceHeader."VAT Date CZL"));
    end;

    [Test]
    procedure ServiceHeaderWithPostingVatDate()
    begin
        // [FEATURE] VAT Date
        Initialize();

        // [GIVEN] Sales Setup with Blank VAT Date
        ServiceMgtSetup.Get();
        ServiceMgtSetup."Default VAT Date CZL" := ServiceMgtSetup."Default VAT Date CZL"::"Posting Date";
        ServiceMgtSetup.Modify();

        // [WHEN] Validate Posting Date
        ServiceHeader.Validate("Posting Date", LibraryRandom.RandDate(30));

        // [THEN] VAT Date is Posting Date
        Assert.AreEqual(ServiceHeader."Posting Date", ServiceHeader."VAT Date CZL", ServiceHeader.FieldCaption(ServiceHeader."VAT Date CZL"));
    end;

    [Test]
    procedure GenJnlLineWithoutUseVatDate()
    begin
        // [FEATURE] VAT Date
        Initialize();

        // [GIVEN] General Ledger Setup without Use VAT Date
        GeneralLedgerSetup."Use VAT Date CZL" := false;
        GeneralLedgerSetup.Modify();

        // [GIVEN] New Gen. Journal Template created
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] New Gen. Journal Batch created
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] New Gen. Journal Line created
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
                        DocumentType::" ", AccountType::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(1000, 2));

        // [WHEN] Validate Posting Date
        GenJournalLine.Validate("Posting Date", LibraryRandom.RandDate(30));

        // [THEN] VAT Date is Posting Date
        Assert.AreEqual(GenJournalLine."Posting Date", GenJournalLine."VAT Date CZL", GenJournalLine.FieldCaption(GenJournalLine."VAT Date CZL"));
    end;

    [Test]
    procedure GenJnlLineWithUseVatDate()
    begin
        // [FEATURE] VAT Date
        Initialize();

        // [GIVEN] General Ledger Setup with Use VAT Date
        GeneralLedgerSetup."Use VAT Date CZL" := true;
        GeneralLedgerSetup.Modify();

        // [GIVEN] New Gen. Journal Template created
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] New Gen. Journal Batch created
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] New Gen. Journal Line created
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
                        DocumentType::" ", AccountType::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(1000, 2));

        // [WHEN] Validate Posting Date
        GenJournalLine.Validate("Posting Date", LibraryRandom.RandDate(30));

        // [THEN] VAT Date is Posting Date
        Assert.AreEqual(GenJournalLine."Posting Date", GenJournalLine."VAT Date CZL", GenJournalLine.FieldCaption(GenJournalLine."VAT Date CZL"));
    end;

    [Test]
    procedure GenJnlLinePostWithVatDate()
    var
        VATEntry: Record "VAT Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        TaxCalculationType: Enum "Tax Calculation Type";
        GeneralPostingType: Enum "General Posting Type";
    begin
        // [FEATURE] VAT Date
        Initialize();

        // [GIVEN] New VAT Posting Setup created
        LibraryERM.CreateVATPostingSetupWithAccounts(VatPostingSetup, TaxCalculationType::"Normal VAT", 10);

        // [GIVEN] New Gen. Journal Template created
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] New Gen. Journal Batch created
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] New balanced Gen. Journal Line created
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
                        DocumentType::" ", AccountType::"G/L Account",
                        LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GeneralPostingType::Sale),
                        AccountType::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(1000, 2));

        // [GIVEN] Validate Posting Date
        GenJournalLine.Validate("Posting Date", LibraryRandom.RandDate(30));

        // [WHEN] Post Gen. Journal Line
        GenJnlPostLine.Run(GenJournalLine);

        // [THEN] VAT Entry has VAT Date
        VatEntry.FindLast();
        Assert.AreEqual(VatEntry."Posting Date", VatEntry."VAT Date CZL", VatEntry.FieldCaption(VatEntry."VAT Date CZL"));
    end;
}
