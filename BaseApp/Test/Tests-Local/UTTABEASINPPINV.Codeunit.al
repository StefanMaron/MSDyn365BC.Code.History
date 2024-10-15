codeunit 144033 "UT TAB EASINPPINV"
{
    // Test for feature: EASINPPINV - Easy Input for Purchase Invoice.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchases] [UT] [VAT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDocAmountVATPurchInvoiceHeaderError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate  Doc. Amount VAT - Purchase Header Trigger of Table ID - 38 Purchase Header for Document Type Invoice.
        ValidateDocAmountVATPurchaseHeaderScenario(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDocAmountVATPurchCrMemoHeaderError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate  Doc. Amount VAT - Purchase Header Trigger of Table ID - 38 Purchase Header for Document Type Credit Memo.
        ValidateDocAmountVATPurchaseHeaderScenario(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDocAmountInclVATPurchInvoiceHeader()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate Doc. Amount Incl. VAT - OnValidate Trigger of Table ID - 38 Purchase Header for Document Type Invoice.
        ValidateDocAmountInclVATPurchaseHeaderScenario(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDocAmountInclVATPurchCrMemoHeader()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate Doc. Amount Incl. VAT - OnValidate Trigger of Table ID - 38 Purchase Header for Document Type Credit Memo.
        ValidateDocAmountInclVATPurchaseHeaderScenario(PurchaseHeader."Document Type"::"Credit Memo")
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ValidateDocAmountVATPurchaseInvoiceSecondLineWithNoVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO] Stan can specify "Doc. Amount VAT" greater than "Doc. Amount Inc. VAT" on multiline purchase invoice having one or more NO VAT line.
        CreatePurchaseDocumentWithTwoLinesNoVATSecondLine(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice);

        PurchaseHeader.CalcFields("Amount Including VAT");
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", PurchaseHeader."Amount Including VAT");
        PurchaseHeader.TestField(
          "Doc. Amount Incl. VAT",
          PurchaseLine[1]."Amount Including VAT" + PurchaseLine[2]."Amount Including VAT");
        PurchaseHeader.TestField("Doc. Amount VAT", PurchaseLine[1]."Amount Including VAT" - PurchaseLine[1].Amount);
        PurchaseHeader.Validate("Doc. Amount VAT", 0);
        PurchaseHeader.Validate("Doc. Amount VAT", PurchaseLine[1]."Amount Including VAT" - PurchaseLine[1].Amount);
        PurchaseHeader.TestField("Doc. Amount VAT", PurchaseLine[1]."Amount Including VAT" - PurchaseLine[1].Amount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ValidateDocAmountVATPurchaseCreditMemoSecondLineWithNoVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO] Stan can specify "Doc. Amount VAT" greater than "Doc. Amount Inc. VAT" on multiline purchase credit memo having one or more NO VAT line.
        CreatePurchaseDocumentWithTwoLinesNoVATSecondLine(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo");

        PurchaseHeader.CalcFields("Amount Including VAT");
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", PurchaseHeader."Amount Including VAT");
        PurchaseHeader.TestField(
          "Doc. Amount Incl. VAT",
          PurchaseLine[1]."Amount Including VAT" + PurchaseLine[2]."Amount Including VAT");
        PurchaseHeader.TestField("Doc. Amount VAT", PurchaseLine[1]."Amount Including VAT" - PurchaseLine[1].Amount);
        PurchaseHeader.Validate("Doc. Amount VAT", 0);
        PurchaseHeader.Validate("Doc. Amount VAT", PurchaseLine[1]."Amount Including VAT" - PurchaseLine[1].Amount);
        PurchaseHeader.TestField("Doc. Amount VAT", PurchaseLine[1]."Amount Including VAT" - PurchaseLine[1].Amount);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Option): Decimal
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(),
          LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Suggested Line", true);
        PurchaseLine.Modify(true);
        exit(PurchaseLine."VAT %");
    end;

    local procedure CreatePurchaseDocumentWithTwoLinesNoVATSecondLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: array[2] of Record "Purchase Line"; DocumentType: Option)
    var
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
        LineAmount: Decimal;
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup[1], VATPostingSetup[1]."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));

        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup[2], VATPostingSetup[1]."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup[2].Validate("VAT Calculation Type", VATPostingSetup[2]."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup[2].Validate("VAT %", 0);
        VATPostingSetup[2].Modify(true);

        LineAmount := LibraryRandom.RandIntInRange(100, 200);

        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup[1]."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine[1], PurchaseHeader, PurchaseLine[1].Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup[1], GLAccount."Gen. Posting Type"::Purchase), 1);
        PurchaseLine[1].Validate("Direct Unit Cost", LineAmount);
        PurchaseLine[1].Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine[2], PurchaseHeader, PurchaseLine[2].Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup[2], GLAccount."Gen. Posting Type"::Purchase), 1);
        PurchaseLine[2].Validate("Direct Unit Cost", -(LineAmount * (100 + VATPostingSetup[1]."VAT %") / 100 - 1));
        PurchaseLine[2].Modify(true);
    end;

    local procedure ValidateDocAmountVATPurchaseHeaderScenario(DocumentType: Option)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup.
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."Doc. Amount Incl. VAT" := LibraryRandom.RandDec(10, 2);

        // Exercise: Validate Doc. Amount VAT with more than Doc. Amount Incl. VAT of Purchase Header.
        asserterror PurchaseHeader.Validate("Doc. Amount VAT", PurchaseHeader."Doc. Amount Incl. VAT" + LibraryRandom.RandDec(10, 2));

        // Verify: Verify Expected error code, Actual error: Doc. Amount VAT must not be more than Doc. Amount Incl. VAT.
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure ValidateDocAmountInclVATPurchaseHeaderScenario(DocumentType: Option)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Currency: Record Currency;
        DocAmountVAT: Decimal;
        DocBaseAmount: Decimal;
        VATPct: Decimal;
    begin
        // Setup: Create Purchase Document.
        Currency.InitRoundingPrecision();
        VATPct := CreatePurchaseDocument(PurchaseHeader, PurchaseLine, DocumentType);

        // Exercise.
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", PurchaseLine."Amount Including VAT");

        // Verify: Verify Doc. Amount VAT on Purchase line. Using calculation formula for DocBaseAmount same as Doc. Amount Incl. VAT - OnValidate Trigger of Table ID - 38 Purchase Header
        DocBaseAmount :=
          Round(
            PurchaseHeader."Doc. Amount Incl. VAT" / (1 + (1 - PurchaseHeader."VAT Base Discount %" / 100) * VATPct / 100),
            Currency."Amount Rounding Precision");
        DocAmountVAT :=
          Round(DocBaseAmount * (1 - PurchaseHeader."VAT Base Discount %" / 100) * VATPct / 100, Currency."Amount Rounding Precision");
        PurchaseHeader.TestField("Doc. Amount VAT", DocAmountVAT);
    end;
}

