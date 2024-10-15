codeunit 145000 Credits
{
    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryCredit: Codeunit "Library - Credit";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        BlockingEntriesErr: Label 'Amount on Credit (LCY) must be equal to ''0''  in Cust. Ledger Entry:';

    local procedure Initialize()
    begin
        LibraryRandom.SetSeed(1);  // Use Random Number Generator to generate the seed for RANDOM function.
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        UpdateCreditsSetup;

        isInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasingCreditWithCustLedgEntries()
    begin
        ReleasingCredit(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasingCreditWithVendLedgEntries()
    begin
        ReleasingCredit(1);
    end;

    local procedure ReleasingCredit(SourceType: Option)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CreditHeader: Record "Credit Header";
        CreditLine1: Record "Credit Line";
        CreditLine2: Record "Credit Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        // 1. Setup:
        Initialize;

        CreateCreditHeader(CreditHeader);

        case SourceType of
            CreditLine1."Source Type"::Customer:
                begin
                    FindCustomerLedgerEntryForInvoice(CustLedgEntry);
                    CreateCreditLine(
                      CreditLine1, CreditHeader, SourceType, CustLedgEntry."Entry No.");
                    FindCustomerLedgerEntryForCrMemo(CustLedgEntry);
                    CreateCreditLine(
                      CreditLine2, CreditHeader, SourceType, CustLedgEntry."Entry No.");
                end;
            CreditLine1."Source Type"::Vendor:
                begin
                    FindVendorLedgerEntryForInvoice(VendLedgEntry);
                    CreateCreditLine(
                      CreditLine1, CreditHeader, SourceType, VendLedgEntry."Entry No.");
                    FindVendorLedgerEntryForCrMemo(VendLedgEntry);
                    CreateCreditLine(
                      CreditLine2, CreditHeader, SourceType, VendLedgEntry."Entry No.");
                end;
        end;

        if Abs(CreditLine1."Amount (LCY)") > Abs(CreditLine2."Amount (LCY)") then
            LibraryCredit.UpdateCreditLine(CreditLine1, -CreditLine2."Amount (LCY)")
        else
            LibraryCredit.UpdateCreditLine(CreditLine2, -CreditLine1."Amount (LCY)");

        // 2. Exercise:

        ReleaseCredit(CreditHeader);

        // 3. Verify:

        CreditHeader.Get(CreditHeader."No.");
        CreditHeader.TestField(Status, CreditHeader.Status::Released);

        // 4. Teardown

        Reopen(CreditHeader);
        CreditHeader.SetRecFilter;
        CreditHeader.DeleteAll(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingCreditWithCustLedgEntries()
    begin
        PostingCredit(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingCreditWithVendLedgEntries()
    begin
        PostingCredit(1);
    end;

    local procedure PostingCredit(SourceType: Option)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CreditHeader: Record "Credit Header";
        CreditLine1: Record "Credit Line";
        CreditLine2: Record "Credit Line";
        PostedCreditHeader: Record "Posted Credit Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        // 1. Setup:
        Initialize;

        CreateCreditHeader(CreditHeader);

        case SourceType of
            CreditLine1."Source Type"::Customer:
                begin
                    FindCustomerLedgerEntryForInvoice(CustLedgEntry);
                    CreateCreditLine(
                      CreditLine1, CreditHeader, SourceType, CustLedgEntry."Entry No.");
                    FindCustomerLedgerEntryForCrMemo(CustLedgEntry);
                    CreateCreditLine(
                      CreditLine2, CreditHeader, SourceType, CustLedgEntry."Entry No.");
                end;
            CreditLine1."Source Type"::Vendor:
                begin
                    FindVendorLedgerEntryForInvoice(VendLedgEntry);
                    CreateCreditLine(
                      CreditLine1, CreditHeader, SourceType, VendLedgEntry."Entry No.");
                    FindVendorLedgerEntryForCrMemo(VendLedgEntry);
                    CreateCreditLine(
                      CreditLine2, CreditHeader, SourceType, VendLedgEntry."Entry No.");
                end;
        end;

        if Abs(CreditLine1."Amount (LCY)") > Abs(CreditLine2."Amount (LCY)") then
            LibraryCredit.UpdateCreditLine(CreditLine1, -CreditLine2."Amount (LCY)")
        else
            LibraryCredit.UpdateCreditLine(CreditLine2, -CreditLine1."Amount (LCY)");

        // 2. Exercise:

        PostCredit(CreditHeader);

        // 3. Verify:

        PostedCreditHeader.Get(CreditHeader."No.");
    end;

    [HandlerFunctions('ModalPageCreditProposalHandler')]
    [Scope('OnPrem')]
    procedure AutomaticSuggestCreditLines()
    var
        CreditHeader: Record "Credit Header";
        CreditLine: Record "Credit Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocNo: array[2] of Code[20];
        Amount: array[2] of Decimal;
    begin
        // 1. Setup:
        Initialize;

        CreateCreditHeader(CreditHeader);

        CreateSalesInvoice(SalesHeader, SalesLine, CreditHeader."Company No.");
        Amount[1] := SalesLine."Amount Including VAT";
        PostedDocNo[1] := PostSalesDocument(SalesHeader);

        CreateSalesCreditMemo(SalesHeader, SalesLine, CreditHeader."Company No.");
        Amount[2] := SalesLine."Amount Including VAT";
        PostedDocNo[2] := PostSalesDocument(SalesHeader);

        // 2. Exercise:

        LibraryCredit.RunSuggestCreditLines(CreditHeader);

        // 3. Verify:

        CreditLine.SetRange("Credit No.", CreditHeader."No.");
        CreditLine.FindSet();
        CreditLine.TestField("Document Type", CreditLine."Document Type"::"Credit Memo");
        CreditLine.TestField("Document No.", PostedDocNo[2]);
        CreditLine.TestField(Amount, -Amount[2]);

        CreditLine.Next;
        CreditLine.TestField("Document Type", CreditLine."Document Type"::Invoice);
        CreditLine.TestField("Document No.", PostedDocNo[1]);
        CreditLine.TestField(Amount, Amount[1]);
    end;

    [HandlerFunctions('ModalPageCreditProposalHandler')]
    [Scope('OnPrem')]
    procedure BlockingEntriesOnReleasedCredits()
    var
        CreditHeader1: Record "Credit Header";
        CreditHeader2: Record "Credit Header";
        CreditLine1: Record "Credit Line";
        CreditLine2: Record "Credit Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // 1. Setup:
        Initialize;

        // create first credit document
        CreateCreditHeader(CreditHeader1);

        CreateSalesInvoice(SalesHeader, SalesLine, CreditHeader1."Company No.");
        PostSalesDocument(SalesHeader);

        CreateSalesCreditMemo(SalesHeader, SalesLine, CreditHeader1."Company No.");
        PostSalesDocument(SalesHeader);

        // suggest credit lines
        LibraryCredit.RunSuggestCreditLines(CreditHeader1);

        CreditLine1.Get(CreditHeader1."No.", 10000);
        CreditLine2.Get(CreditHeader1."No.", 20000);

        if Abs(CreditLine1."Amount (LCY)") > Abs(CreditLine2."Amount (LCY)") then
            LibraryCredit.UpdateCreditLine(CreditLine1, -CreditLine2."Amount (LCY)")
        else
            LibraryCredit.UpdateCreditLine(CreditLine2, -CreditLine1."Amount (LCY)");

        // release first credit document
        ReleaseCredit(CreditHeader1);

        // create second credit document with same customer
        CreateCreditHeaderWithCustomer(CreditHeader2, CreditHeader1."Company No.");

        // 2. Exercise
        // suggest credit lines fails
        asserterror LibraryCredit.RunSuggestCreditLines(CreditHeader2);

        // 3. Verify
        Assert.ExpectedError(BlockingEntriesErr);
    end;

    local procedure CreateCreditHeader(var CreditHeader: Record "Credit Header")
    begin
        CreateCreditHeaderWithCustomer(CreditHeader, LibrarySales.CreateCustomerNo);
    end;

    local procedure CreateCreditHeaderWithCustomer(var CreditHeader: Record "Credit Header"; CustomerNo: Code[20])
    begin
        LibraryCredit.CreateCreditHeader(CreditHeader, CustomerNo);
    end;

    local procedure CreateCreditLine(var CreditLine: Record "Credit Line"; CreditHeader: Record "Credit Header"; SourceType: Option; SourceEntryNo: Integer)
    begin
        LibraryCredit.CreateCreditLine(CreditLine, CreditHeader, SourceType, SourceEntryNo);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account"; WithVATPostingSetup: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccountNo: Code[20];
    begin
        if not WithVATPostingSetup then
            LibraryERM.CreateGLAccount(GLAccount)
        else begin
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
            GLAccount.Get(GLAccountNo);
        end;
    end;

    local procedure CreateSalesDocument(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line"; DocumentType: Option; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHdr, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLn, SalesHdr, SalesLn.Type::"G/L Account", GetNewGLAccountNo(true), 1);
        SalesLn.Validate("Unit Price", LibraryRandom.RandDec(10000, 2));
        SalesLn.Modify(true);
    end;

    local procedure CreateSalesCreditMemo(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line"; CustomerNo: Code[20])
    begin
        CreateSalesDocument(SalesHdr, SalesLn, SalesHdr."Document Type"::"Credit Memo", CustomerNo);
    end;

    local procedure CreateSalesInvoice(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line"; CustomerNo: Code[20])
    begin
        CreateSalesDocument(SalesHdr, SalesLn, SalesHdr."Document Type"::Invoice, CustomerNo);
    end;

    local procedure GetNewGLAccountNo(WithVATPostingSetup: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        CreateGLAccount(GLAccount, WithVATPostingSetup);
        exit(GLAccount."No.");
    end;

    local procedure FindCustomerLedgerEntryForInvoice(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        LibraryCredit.FindCustomerLedgerEntry(CustLedgEntry, CustLedgEntry."Document Type"::Invoice);
    end;

    local procedure FindCustomerLedgerEntryForCrMemo(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        LibraryCredit.FindCustomerLedgerEntry(CustLedgEntry, CustLedgEntry."Document Type"::"Credit Memo");
    end;

    local procedure FindVendorLedgerEntryForInvoice(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        LibraryCredit.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::Invoice);
    end;

    local procedure FindVendorLedgerEntryForCrMemo(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        LibraryCredit.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::"Credit Memo");
    end;

    local procedure PostCredit(var CreditHeader: Record "Credit Header")
    begin
        LibraryCredit.RunPostCredit(CreditHeader);
    end;

    local procedure PostSalesDocument(var SalesHdr: Record "Sales Header"): Code[20]
    begin
        exit(LibrarySales.PostSalesDocument(SalesHdr, true, true));
    end;

    local procedure ReleaseCredit(var CreditHeader: Record "Credit Header")
    begin
        LibraryCredit.RunReleaseCredit(CreditHeader);
    end;

    local procedure Reopen(var CreditHeader: Record "Credit Header")
    begin
        LibraryCredit.RunReopenCredit(CreditHeader);
    end;

    local procedure UpdateCreditsSetup()
    var
        CreditsSetup: Record "Credits Setup";
    begin
        CreditsSetup.Get();
        CreditsSetup."Credit Nos." := LibraryERM.CreateNoSeriesCode;
        CreditsSetup."Credit Bal. Account No." := LibraryERM.CreateGLAccountNo;
        CreditsSetup."Credit Proposal By" := CreditsSetup."Credit Proposal By"::"Registration No.";
        CreditsSetup."Max. Rounding Amount" := 1;
        CreditsSetup."Debit Rounding Account" := LibraryERM.CreateGLAccountNo;
        CreditsSetup."Credit Rounding Account" := LibraryERM.CreateGLAccountNo;
        CreditsSetup.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalPageCreditProposalHandler(var CreditProposal: TestPage "Credit Proposal")
    begin
        CreditProposal.CustLedgEntries.First;
        CreditProposal.CustLedgEntries.Mark.Invoke;
        CreditProposal.CustLedgEntries.Next;
        CreditProposal.CustLedgEntries.Mark.Invoke;
        CreditProposal.OK.Invoke;
    end;
}

