codeunit 134018 "ERM Payment Tolerance Purchase"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Tolerance] [Purchase]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        AmountErrorMessage: Label '%1 must be %2 in %3 %4 %5.';
        DocumentType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        ExpectedMessage: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithLCY()
    var
        DocumentNo: Code[20];
        ExpectedPmtTolAmount: Decimal;
    begin
        // Covers Test Case 124103,124104.
        // Check Vendor Ledger Entry for Payment Tolerance after posting Purchase Invoice without Currency.

        // Create and Post Purchase Invoice without Currency.
        DocumentNo := CreateAndPostPurchaseDocument('', DocumentType::Invoice);

        // Verify: Verify Vendor Ledger Entry Amount.
        ExpectedPmtTolAmount := CalcPaymentTolInvoiceLCY(DocumentNo);
        VerifyMaxPaymentTolInvoice(DocumentNo, ExpectedPmtTolAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoWithLCY()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        DocumentNo: Code[20];
    begin
        // Covers Test Case 124087,124088.
        // Check Vendor Ledger Entry for Payment Tolerance after posting Purchase Credit Memo without Currency.

        // Create and Post Purchase Credit Memo without Currency.
        DocumentNo := CreateAndPostPurchaseDocument('', DocumentType::"Credit Memo");

        // Verify: Verify Vendor Ledger Entry Amount.
        PurchCrMemoHdr.Get(DocumentNo);
        PurchCrMemoHdr.CalcFields("Amount Including VAT");
        VerifyVendorLedgerEntry(PurchCrMemoHdr."Amount Including VAT", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithFCY()
    var
        DocumentNo: Code[20];
        ExpectedPmtTolAmount: Decimal;
    begin
        // Covers Test Case 124103,124104.
        // Check Vendor Ledger Entry for Payment Tolerance after posting Purchase Invoice with Currency.

        // Create and Post Purchase Invoice with Currency.
        DocumentNo := CreateAndPostPurchaseDocument(CreateCurrency, DocumentType::Invoice);

        // Verify: Verify Vendor Ledger Entry Amount.
        ExpectedPmtTolAmount := CalcPaymentTolInvoiceFCY(DocumentNo);
        VerifyMaxPaymentTolInvoice(DocumentNo, ExpectedPmtTolAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoWithFCY()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        DocumentNo: Code[20];
    begin
        // Covers Test Case 124087,124088.
        // Check Vendor Ledger Entry  for Payment Tolerance after posting Purchase Credit Memo with Currency.

        // Create and Post Purchase Credit Memo with Currency.
        DocumentNo := CreateAndPostPurchaseDocument(CreateCurrency, DocumentType::"Credit Memo");

        // Verify: Verify Vendor Ledger Entry Amount.
        PurchCrMemoHdr.Get(DocumentNo);
        PurchCrMemoHdr.CalcFields("Amount Including VAT");
        VerifyVendorLedgerEntry(PurchCrMemoHdr."Amount Including VAT", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoCopyDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo";
        DocumentNo: Code[20];
    begin
        // Covers Test Case 124089.
        // Check Vendor Ledger Entry for Payment Tolerance after posting Purchase Credit Memo and Copy Document.

        // Setup: Update General ledger Setup and Create and Post Purchase Invoice.
        Initialize;
        LibraryPmtDiscSetup.SetPmtTolerance(5);

        CreatePurchaseDocument(PurchaseHeader, '', PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchaseHeader.Init;
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.Insert(true);

        // Exercise: Create and Post Purchase Credit Memo after Copy Document with Document Type Posted Invoice.
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, DocumentType::"Posted Invoice", DocumentNo, true, true);
        PurchaseHeader.SetRange("Applies-to Doc. No.", DocumentNo);
        PurchaseHeader.FindFirst;
        PurchaseHeader.Validate("Vendor Cr. Memo No.", DocumentNo);
        PurchaseHeader.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ExecuteUIHandler;  // Need to invoke confirmation message everytime to prevent test failures in ES build.

        // Verify: Max Payment Tolerance is zero for Credit Memo applied to Invoice.
        VerifyMaxPaymentTolCreditMemo(DocumentNo, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoCopyDocumentLineOnly()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo";
        DocumentNo: Code[20];
        ExpectedPmtTolAmount: Decimal;
    begin
        // Covers Test Case 124090.
        // Check Vendor Ledger Entry for Payment Tolerance after posting Purchase Credit Memo and Copy Document with Only Line.

        // Setup: Update General Ledger Setup and Create and Post Purchase invoice and take a Random quantity.
        Initialize;
        LibraryPmtDiscSetup.SetPmtTolerance(5);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Payment Discount %", LibraryRandom.RandInt(5)); // Use Random value for Payment Discount.
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem,
          LibraryRandom.RandInt(10));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem,
          LibraryRandom.RandInt(10));
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        // Exercise: Create and Post Purchase Credit Memo after Copy Document with Document Type Posted Invoice.
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, DocumentType::"Posted Invoice", DocumentNo, false, true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ExecuteUIHandler;  // Need to invoke confirmation message everytime to prevent test failures in ES build.

        // Verify: Verify Max Payment Tolerance field in Vendor Ledger Entry.
        ExpectedPmtTolAmount := CalcPaymentTolCreditMemoLCY(DocumentNo);
        VerifyMaxPaymentTolCreditMemo(DocumentNo, ExpectedPmtTolAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoCopyDocumentOpenInv()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo";
        DocumentNo: Code[20];
        ExpectedPmtTolAmount: Decimal;
    begin
        // Covers Test Case 124091.
        // Check Vendor Ledger Entry for Payment Tolerance after posting Purchase Credit Memo and Copy Document with Document Type Invoice.

        // Setup: Update General Ledger Setup and Create Purchase Invoice and Insert new record with Document Type Credit memo.
        Initialize;
        LibraryPmtDiscSetup.SetPmtTolerance(5);
        CreatePurchaseDocument(PurchaseHeader, '', PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Payment Discount %", LibraryRandom.RandInt(5)); // Use Random value for Payment Discount.
        PurchaseHeader.Modify(true);
        PurchaseHeader.Init;
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.Insert(true);

        // Exercise: Create and Post Purchase Credit Memo after Copy Document with Document Type Invoice.
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, DocumentType::Invoice, PurchaseHeader."No.", true, true);
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        PurchaseHeader.FindFirst;
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ExecuteUIHandler;  // Need to invoke confirmation message everytime to prevent test failures in ES build.

        // Verify: Verify Max Payment Tolerance field in Vendor Ledger Entry.
        ExpectedPmtTolAmount := CalcPaymentTolCreditMemoLCY(DocumentNo);
        VerifyMaxPaymentTolCreditMemo(DocumentNo, ExpectedPmtTolAmount);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Payment Tolerance Purchase");
        LibrarySetupStorage.Restore;
        ExecuteUIHandler;  // Need to invoke confirmation message everytime to prevent test failures in ES build.

        // Setup demo data.
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Payment Tolerance Purchase");
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.CreateGeneralPostingSetupData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;
        isInitialized := true;
        Commit;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Payment Tolerance Purchase");
    end;

    local procedure CreateAndPostPurchaseDocument(CurrencyCode: Code[10]; DocType: Option): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup: Update General Ledger Setup and Create Purchase Document.
        Initialize;
        LibraryPmtDiscSetup.SetPmtTolerance(5);
        CreatePurchaseDocument(PurchaseHeader, CurrencyCode, DocType);

        // Exercise: Post Purchase Document.
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        // Use Random value for Payment Tolerance and Max Payment Tolerance Amount.
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Payment Tolerance %", LibraryRandom.RandInt(5));
        Currency.Validate("Max. Payment Tolerance Amount", LibraryRandom.RandInt(5));
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
    begin
        // Find Payment Terms Code and Update.
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify(true);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Validate("Application Method", Vendor."Application Method"::Manual);
        Vendor.Validate("Block Payment Tolerance", false);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        // Cost should be small enough to not make a document exceed Max. Payment Tolerance
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(7));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10]; DocumentType: Option)
    var
        PurchaseLine: Record "Purchase Line";
        Counter: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        // Use Counter for Creating Multiple Purchase Lines with Random Quantity.
        for Counter := 1 to LibraryRandom.RandInt(3) do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem, LibraryRandom.RandInt(3));
            if DocumentType = PurchaseLine."Document Type"::"Credit Memo" then begin
                PurchaseLine.Validate("Qty. to Receive", 0); // Quantity to Receive must be 0 for Purchase Credit Memo.
                PurchaseLine.Modify(true);
            end;
        end;
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst;
        VendorLedgerEntry.CalcFields(Amount);
    end;

    local procedure CalcPaymentTolInvoiceFCY(DocumentNo: Code[20]): Decimal
    var
        Currency: Record Currency;
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        Currency.Get(PurchInvHeader."Currency Code");
        exit(PurchInvHeader."Amount Including VAT" * Currency."Payment Tolerance %" / 100);
    end;

    local procedure CalcPaymentTolInvoiceLCY(DocumentNo: Code[20]): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        GeneralLedgerSetup.Get;
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        exit(PurchInvHeader."Amount Including VAT" * GeneralLedgerSetup."Payment Tolerance %" / 100);
    end;

    local procedure CalcPaymentTolCreditMemoLCY(DocumentNo: Code[20]): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        GeneralLedgerSetup.Get;
        PurchCrMemoHdr.Get(DocumentNo);
        PurchCrMemoHdr.CalcFields("Amount Including VAT");
        exit(PurchCrMemoHdr."Amount Including VAT" * GeneralLedgerSetup."Payment Tolerance %" / 100);
    end;

    local procedure VerifyVendorLedgerEntry(Amount: Decimal; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get;
        FindVendorLedgerEntry(VendorLedgerEntry, DocumentNo);
        Assert.AreNearlyEqual(Amount, VendorLedgerEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErrorMessage, VendorLedgerEntry.FieldCaption(Amount), Amount, VendorLedgerEntry.TableCaption,
            VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));
    end;

    local procedure VerifyMaxPaymentTolInvoice(DocumentNo: Code[20]; ExpectedPmtTolAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get;
        FindVendorLedgerEntry(VendorLedgerEntry, DocumentNo);
        Assert.AreNearlyEqual(-ExpectedPmtTolAmount, VendorLedgerEntry."Max. Payment Tolerance",
          GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(AmountErrorMessage, VendorLedgerEntry.FieldCaption(Amount),
            ExpectedPmtTolAmount, VendorLedgerEntry.TableCaption, VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));
    end;

    local procedure VerifyMaxPaymentTolCreditMemo(DocumentNo: Code[20]; ExpectedPmtTolAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get;
        FindVendorLedgerEntry(VendorLedgerEntry, DocumentNo);
        Assert.AreNearlyEqual(ExpectedPmtTolAmount, VendorLedgerEntry."Max. Payment Tolerance",
          GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(AmountErrorMessage, VendorLedgerEntry.FieldCaption(Amount),
            ExpectedPmtTolAmount, VendorLedgerEntry.TableCaption, VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy message. Required for executing the test case successfully.
        if Confirm(StrSubstNo(ExpectedMessage)) then;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

