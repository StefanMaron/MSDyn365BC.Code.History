codeunit 144204 "Tax Purchase Document"
{
    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryRandom.SetSeed(1);  // Use Random Number Generator to generate the seed for RANDOM function.
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        UpdateGLSetup;

        isInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCalculationFromAbovePurchaseOrder()
    var
        PurchHdr: Record "Purchase Header";
    begin
        VATCalculationFromAbove(PurchHdr."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCalculationFromAbovePurchaseInvoice()
    var
        PurchHdr: Record "Purchase Header";
    begin
        VATCalculationFromAbove(PurchHdr."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCalculationFromAbovePurchaseCrMemo()
    var
        PurchHdr: Record "Purchase Header";
    begin
        VATCalculationFromAbove(PurchHdr."Document Type"::"Credit Memo");
    end;

    local procedure VATCalculationFromAbove(DocumentType: Option)
    var
        PurchHdr: Record "Purchase Header";
        PurchLn: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedDocumentNo: Code[20];
        Amount: Decimal;
        VATAmount: Decimal;
    begin
        // 1. Setup
        Initialize;

        Amount := 1320;
        VATAmount := 119.99;

        CreateVATPostingSetup(VATPostingSetup);
        CreatePurchaseDocument(PurchHdr, PurchLn, VATPostingSetup, DocumentType, Amount);

        // 2. Exercise
        PostedDocumentNo := PostPurchaseDocument(PurchHdr);

        // 3. Verify
        VATEntry.SetRange("Document No.", PostedDocumentNo);
        VATEntry.SetRange("Posting Date", PurchHdr."Posting Date");
        VATEntry.FindFirst;
        if DocumentType = PurchHdr."Document Type"::"Credit Memo" then
            VATEntry.TestField(Amount, -VATAmount)
        else
            VATEntry.TestField(Amount, VATAmount);
    end;

    local procedure CreatePurchaseDocument(var PurchHdr: Record "Purchase Header"; var PurchLn: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Option; Amount: Decimal)
    var
        VendorNo: Code[20];
    begin
        VendorNo :=
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchHdr, DocumentType, VendorNo);
        PurchHdr.Validate("Prices Including VAT", true);
        PurchHdr.Modify();

        LibraryPurchase.CreatePurchaseLine(
          PurchLn, PurchHdr, PurchLn.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, 0), 1);
        PurchLn.Validate("Direct Unit Cost", Amount);
        PurchLn.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10);
    end;

    local procedure PostPurchaseDocument(var PurchHdr: Record "Purchase Header"): Code[20]
    begin
        exit(LibraryPurchase.PostPurchaseDocument(PurchHdr, true, true));
    end;

    local procedure UpdateGLSetup()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("VAT Coeff. Rounding Precision", 0.0001);
        GLSetup.Validate("Round VAT Coeff.", true);
        GLSetup.Modify();
    end;
}

