codeunit 144203 "Tax Sales Document"
{
    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
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
    procedure VATCalculationFromAboveSalesOrder()
    var
        SalesHdr: Record "Sales Header";
    begin
        VATCalculationFromAbove(SalesHdr."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCalculationFromAboveSalesInvoice()
    var
        SalesHdr: Record "Sales Header";
    begin
        VATCalculationFromAbove(SalesHdr."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCalculationFromAboveSalesCrMemo()
    var
        SalesHdr: Record "Sales Header";
    begin
        VATCalculationFromAbove(SalesHdr."Document Type"::"Credit Memo");
    end;

    local procedure VATCalculationFromAbove(DocumentType: Option)
    var
        SalesHdr: Record "Sales Header";
        SalesLn: Record "Sales Line";
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
        CreateSalesDocument(SalesHdr, SalesLn, VATPostingSetup, DocumentType, Amount);

        // 2. Exercise
        PostedDocumentNo := PostSalesDocument(SalesHdr);

        // 3. Verify
        VATEntry.SetRange("Document No.", PostedDocumentNo);
        VATEntry.SetRange("Posting Date", SalesHdr."Posting Date");
        VATEntry.FindFirst;
        if DocumentType = SalesHdr."Document Type"::"Credit Memo" then
            VATEntry.TestField(Amount, VATAmount)
        else
            VATEntry.TestField(Amount, -VATAmount);
    end;

    local procedure CreateSalesDocument(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Option; UnitPrice: Decimal)
    var
        CustomerNo: Code[20];
    begin
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHdr, DocumentType, CustomerNo);
        SalesHdr.Validate("Prices Including VAT", true);
        SalesHdr.Modify();

        LibrarySales.CreateSalesLine(
          SalesLn, SalesHdr, SalesLn.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, 0), 1);
        SalesLn.Validate("Unit Price", UnitPrice);
        SalesLn.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10);
    end;

    local procedure PostSalesDocument(var SalesHdr: Record "Sales Header"): Code[20]
    begin
        exit(LibrarySales.PostSalesDocument(SalesHdr, true, true));
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

