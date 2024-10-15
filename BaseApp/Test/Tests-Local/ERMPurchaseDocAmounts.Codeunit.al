codeunit 144032 "ERM Purchase Doc. Amounts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Document Totals] [Document Amount]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        TotalAmountErr: Label 'Total amount (%1) is not equal to total of lines (%2)';
        LibraryRandom: Codeunit "Library - Random";
        ValueMustNotEqualMsg: Label 'Value must not be equal';
        ValueMustEqualMsg: Label 'Value must be equal';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoiceDocAmountInclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeaderNo: Code[20];
    begin
        // [GIVEN] Create Purchase Invoice with Document Amount Including VAT.
        Initialize;
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Update Doc. Amount Incl. VAT and post Purchase Invoice for Ship and Invoice.
        PurchInvHeaderNo :=
          UpdateAndPostPurchaseDocument(
            PurchaseHeader, PurchaseLine, PurchaseLine."Line Amount" + PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100);

        // [THEN] Verify Purchase Invoice posted successfully.
        VerifyPurchaseInvoiceLine(PurchInvHeaderNo, PurchaseHeader."Doc. Amount Incl. VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchCrMemoDocAmountInclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdrNo: Code[20];
    begin
        // [GIVEN] Create Purchase Credit Memo with Document Amount Including VAT.
        Initialize;
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo");

        // [WHEN] Update Doc. Amount Incl. VAT and post Purchase Credit Memo for Ship and Invoice.
        PurchCrMemoHdrNo :=
          UpdateAndPostPurchaseDocument(
            PurchaseHeader, PurchaseLine, PurchaseLine."Line Amount" + PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100);

        // [THEN] Verify Purchase Credit Memo posted successfully.
        VerifyPurchaseCreditMemoLine(PurchCrMemoHdrNo, PurchaseHeader."Doc. Amount Incl. VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoiceWithDocAmountInclVATError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Post Purchase Invoice with wrong Document Amount Including VAT.
        Initialize;
        PostPurchDocWithWrongDocAmountInclVAT("Purchase Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchCrMemoWithDocAmountInclVATError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Post Purchase Credit Memo with wrong Document Amount Including VAT.
        Initialize;
        PostPurchDocWithWrongDocAmountInclVAT("Purchase Document Type"::"Credit Memo");
    end;

    local procedure PostPurchDocWithWrongDocAmountInclVAT(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        SetCheckDocTotalAmounts(true);
        // [GIVEN] Create Purchase Document with wrong Document Amount Including VAT.
        CreatePurchaseDocument(PurchaseLine, DocumentType);

        // [WHEN] Update Doc. Amount Incl. VAT and post Purchase Document.
        asserterror UpdateAndPostPurchaseDocument(PurchaseHeader, PurchaseLine, LibraryRandom.RandDec(10, 2));  // Taking Random value for Doc. Amount Incl. VAT other than calculated value from Purchase Line.

        // [THEN] Verify Posting is not allowed with wrong Document Amount Including VAT.
        Assert.ExpectedError(
          StrSubstNo(
            TotalAmountErr, PurchaseHeader."Doc. Amount Incl. VAT",
            (PurchaseLine."Line Amount" + PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoiceCheckDocTotalAmountsFalse()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeaderNo: Code[20];
    begin
        // [GIVEN] Update Check Doc. Total Amounts - FALSE on Purchases & Payables Setup, Create Purchase Invoice with wrong Document Amount Including VAT.
        Initialize;
        SetCheckDocTotalAmounts(false);
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Update Doc. Amount Incl. VAT and post Purchase Invoice for Ship and Invoice.
        PurchInvHeaderNo := UpdateAndPostPurchaseDocument(PurchaseHeader, PurchaseLine, LibraryRandom.RandDec(10, 2));  // Taking Random value for Doc. Amount Incl. VAT other than calculated value from Purchase Line.

        // [THEN] Verify Purchase Invoice posted successfully with wrong Document Amount Including VAT.
        VerifyPurchaseInvoiceLine(PurchInvHeaderNo, PurchaseLine."Line Amount" + PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchCrMemoCheckDocTotalAmountsFalse()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHeaderNo: Code[20];
    begin
        // [GIVEN] Update Check Doc. Total Amounts - FALSE on Purchases & Payables Setup, Create Purchase Credit Memo with wrong Document Amount Including VAT.
        Initialize;
        SetCheckDocTotalAmounts(false);
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo");

        // [WHEN] Update Doc. Amount Incl. VAT and post Purchase Credit Memo for Ship and Invoice.
        PurchCrMemoHeaderNo := UpdateAndPostPurchaseDocument(PurchaseHeader, PurchaseLine, LibraryRandom.RandDec(10, 2));  // Taking Random value for Doc. Amount Incl. VAT other than calculated value from Purchase Line.

        // [THEN] Verify Purchase Credit Memo posted successfully with wrong Document Amount Including VAT.
        VerifyPurchaseCreditMemoLine(
          PurchCrMemoHeaderNo, PurchaseLine."Line Amount" + PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithDiffItemsMultipleLinesDocAmountInclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Purchase Invoice with multiple lines for different Items having different VAT %.
        Initialize;
        PurchDocWithDiffItemsMultipleLinesDocAmountInclVAT("Purchase Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoDiffItemsWithMultipleLinesDocAmtInclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Purchase Credit Memo with multiple lines for different Items having different VAT %.
        Initialize;
        PurchDocWithDiffItemsMultipleLinesDocAmountInclVAT("Purchase Document Type"::"Credit Memo");
    end;

    local procedure PurchDocWithDiffItemsMultipleLinesDocAmountInclVAT(DocumentType: Enum "Purchase Document Type")
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        DocAmountIncVAT: Decimal;
        ExpectedDocAmountVAT: Decimal;
    begin
        // [GIVEN] Create Purchase Document with multiple lines for different Items having different VAT %.
        CreatePurchaseDocument(PurchaseLine, DocumentType);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreateItemWithDiffVATProdPostingGroup(Item, PurchaseLine."VAT Prod. Posting Group");
        CreatePurchaseLine(PurchaseLine2, PurchaseHeader, Item."No.", Item."Unit Cost");
        DocAmountIncVAT :=
          PurchaseLine."Line Amount" +
          PurchaseLine."Line Amount" *
          PurchaseLine."VAT %" / 100 + PurchaseLine2."Line Amount" + PurchaseLine2."Line Amount" * PurchaseLine2."VAT %" / 100;
        ExpectedDocAmountVAT :=
          PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100 + PurchaseLine2."Line Amount" * PurchaseLine."VAT %" / 100;

        // [WHEN] Update Doc. Amount Incl. VAT on Purchase Header.
        UpdatePurchaseHeader(PurchaseHeader, DocAmountIncVAT);

        // [THEN] Verify Document Amount VAT on Purchase Header is updated with VAT % of first line for both the lines.
        Assert.AreNotEqual(ExpectedDocAmountVAT, PurchaseHeader."Doc. Amount VAT", ValueMustNotEqualMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithMultipleLinesDocAmountInclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Purchase Invoice with multiple lines for same Item.
        Initialize;
        PurchDocWithMultipleLinesDocAmountInclVAT("Purchase Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithMultipleLinesDocAmountInclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Purchase Credit Memo with multiple lines for same Item.
        Initialize;
        PurchDocWithMultipleLinesDocAmountInclVAT("Purchase Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocAmountInclVATWhenSingleLineWithoutAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocAmountInclVAT: Decimal;
    begin
        // [SCENARIO 280476] No error when validate Doc Amount Incl. VAT in Purchase Header when only zero amount lines present in purch. document
        // [SCENARIO] Doc. Amount VAT is <zero> in this case
        Initialize;
        DocAmountInclVAT := LibraryRandom.RandDecInRange(1000, 2000, 2);

        // [GIVEN] Purchase Invoice with Line having Qty = 1 and Unit Cost is <zero>
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Unit Cost", 0);
        PurchaseLine.Modify(true);

        // [WHEN] Validate Doc. Amount Incl. VAT = 1000 in Purchase Header
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", DocAmountInclVAT);

        // [THEN] Doc. Amount Incl. VAT = 1000 in Purchase Header
        PurchaseHeader.TestField("Doc. Amount Incl. VAT", DocAmountInclVAT);

        // [THEN] Doc. Amount VAT is <zero> in Purchase Header
        PurchaseHeader.TestField("Doc. Amount VAT", 0);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purchase Doc. Amounts");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purchase Doc. Amounts");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purchase Doc. Amounts");
    end;

    local procedure PurchDocWithMultipleLinesDocAmountInclVAT(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        DocAmountInclVAT: Decimal;
        ExpectedDocAmountVAT: Decimal;
    begin
        // [GIVEN] Create Purchase Document with multiple lines for same Item.
        CreatePurchaseDocument(PurchaseLine, DocumentType);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine."No.", PurchaseLine."Direct Unit Cost");
        DocAmountInclVAT :=
          PurchaseLine."Line Amount" +
          PurchaseLine."Line Amount" *
          PurchaseLine."VAT %" / 100 + PurchaseLine2."Line Amount" + PurchaseLine2."Line Amount" * PurchaseLine2."VAT %" / 100;
        ExpectedDocAmountVAT :=
          Round(PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100 + PurchaseLine2."Line Amount" * PurchaseLine2."VAT %" / 100);

        // [WHEN] Update Doc. Amount Incl. VAT on Purchase Header.
        UpdatePurchaseHeader(PurchaseHeader, DocAmountInclVAT);

        // [THEN] Verify Document Amount VAT on Purchase Header is updated correctly.
        Assert.AreEqual(ExpectedDocAmountVAT, PurchaseHeader."Doc. Amount VAT", ValueMustEqualMsg);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandInt(10));
        Item.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Item: Record Item;
    begin
        CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item."No.", Item."Unit Cost");
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));  // Using Random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateItemWithDiffVATProdPostingGroup(var Item: Record Item; VATProdPostingGroupCode: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATProductPostingGroup.SetFilter(Code, '<>%1', VATProdPostingGroupCode);  // VAT Product Posting Group should be different for second Items
        VATProductPostingGroup.FindFirst;
        CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        Item.Modify(true);
    end;

    local procedure UpdatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocAmountInclVAT: Decimal)
    begin
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID);
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", DocAmountInclVAT);
        PurchaseHeader.Modify(true);
    end;

    local procedure SetCheckDocTotalAmounts(CheckTotals: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Check Doc. Total Amounts", CheckTotals);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; DocAmountInclVAT: Decimal) DocumentNo: Code[20]
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        UpdatePurchaseHeader(PurchaseHeader, DocAmountInclVAT);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure VerifyPurchaseInvoiceLine(DocumentNo: Code[20]; AmountIncludingVAT: Decimal)
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst;
        PurchInvLine.TestField("Amount Including VAT", AmountIncludingVAT);
    end;

    local procedure VerifyPurchaseCreditMemoLine(DocumentNo: Code[20]; AmountIncludingVAT: Decimal)
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        PurchCrMemoLine.FindFirst;
        PurchCrMemoLine.TestField("Amount Including VAT", AmountIncludingVAT);
    end;
}

