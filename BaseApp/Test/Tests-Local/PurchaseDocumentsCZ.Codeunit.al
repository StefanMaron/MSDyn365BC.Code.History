codeunit 145009 "Purchase Documents CZ"
{
    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        GLAccMustBeSameErr: Label 'G/L Accounts must be the same.';
        OppositeSignErr: Label 'Amounts must have the opposite sign.';

    local procedure Initialize()
    begin
        LibraryRandom.SetSeed(1);  // Use Random Number Generator to generate the seed for RANDOM function.
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        UpdatePurchaseSetup;

        isInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RedEntriesFromPurchaseCorrectionDocuments()
    var
        GLEntry1: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
        PurchHdr: Record "Purchase Header";
        PurchLn: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchInvHdr: Record "Purch. Inv. Header";
        PostedDocumentNo: array[2] of Code[20];
    begin
        // 1. Setup
        Initialize;

        // create and post sales invoice
        CreatePurchaseDocument(PurchHdr, PurchLn, PurchHdr."Document Type"::Invoice);
        PostedDocumentNo[1] := PostPurchaseDocument(PurchHdr);

        // create and post credit memo from posted sales invoice
        Clear(PurchHdr);
        PurchHdr.Validate("Document Type", PurchHdr."Document Type"::"Credit Memo");
        PurchHdr.Insert(true);
        LibraryPurchase.CopyPurchaseDocument(PurchHdr, 7, PostedDocumentNo[1], true, false);
        PurchHdr.Get(PurchHdr."Document Type", PurchHdr."No.");
        PurchHdr.Validate("Vendor Cr. Memo No.", PurchHdr."No.");
        PurchHdr.Validate(Correction, true);
        PurchHdr.Modify(true);

        // 2. Exercise
        PostedDocumentNo[2] := PostPurchaseDocument(PurchHdr);

        // 3. Verify
        PurchInvHdr.Get(PostedDocumentNo[1]);
        PurchCrMemoHdr.Get(PostedDocumentNo[2]);

        GetGLEntry(GLEntry1, PurchInvHdr."No.", PurchInvHdr."Posting Date");
        GetGLEntry(GLEntry2, PurchCrMemoHdr."No.", PurchCrMemoHdr."Posting Date");

        Assert.IsTrue(
          GLEntry1."G/L Account No." = GLEntry2."G/L Account No.", GLAccMustBeSameErr);
        Assert.IsTrue(
          GLEntry1.Amount + GLEntry2.Amount = 0, OppositeSignErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [Obsolete('The functionality of general ledger entry description will be removed and this function should not be used. (Removed in release 01.2021)','16.0')]
    procedure TransferingDescriptionToGLEntriesForPurchaseOrder()
    var
        PurchHdr: Record "Purchase Header";
    begin
        TransferingDescriptionToGLEntries(PurchHdr."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    [Obsolete('The functionality of general ledger entry description will be removed and this function should not be used. (Removed in release 01.2021)','16.0')]
    procedure TransferingDescriptionToGLEntriesForPurchaseInvoice()
    var
        PurchHdr: Record "Purchase Header";
    begin
        TransferingDescriptionToGLEntries(PurchHdr."Document Type"::Invoice);
    end;

    local procedure TransferingDescriptionToGLEntries(DocumentType: Option)
    var
        GLEntry: Record "G/L Entry";
        PurchHdr: Record "Purchase Header";
        PurchLn: Record "Purchase Line";
        PostedDocumentNo: Code[20];
    begin
        // 1. Setup
        Initialize;

        CreatePurchaseDocument(PurchHdr, PurchLn, DocumentType);

        // 2. Exercise
        PostedDocumentNo := PostPurchaseDocument(PurchHdr);

        // 3. Verify
        GLEntry.Init();
        GLEntry.SetRange("Document No.", PostedDocumentNo);
        GLEntry.SetRange("Posting Date", PurchHdr."Posting Date");
        GLEntry.FindFirst;
        GLEntry.TestField(Description, PurchLn.Description);
    end;

    local procedure CreatePurchaseDocument(var PurchHdr: Record "Purchase Header"; var PurchLn: Record "Purchase Line"; DocumentType: Option)
    begin
        LibraryPurchase.CreatePurchHeader(PurchHdr, DocumentType, LibraryPurchase.CreateVendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchLn, PurchHdr, PurchLn.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup, 1);
        PurchLn.Validate(Description, PurchHdr."No.");
        PurchLn.Validate("Direct Unit Cost", LibraryRandom.RandDec(10000, 2));
        PurchLn.Modify(true);
    end;

    local procedure GetGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; PostingDate: Date)
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.FindFirst;
    end;

    local procedure PostPurchaseDocument(var PurchHdr: Record "Purchase Header"): Code[20]
    begin
        exit(LibraryPurchase.PostPurchaseDocument(PurchHdr, true, true));
    end;

    local procedure UpdatePurchaseSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("G/L Entry as Doc. Lines (Acc.)", true);
        PurchasesPayablesSetup.Validate("G/L Entry as Doc. Lines (Item)", true);
        PurchasesPayablesSetup.Validate("G/L Entry as Doc. Lines (FA)", true);
        PurchasesPayablesSetup.Validate("G/L Entry as Doc. Lines (Acc.)", true);
        PurchasesPayablesSetup.Modify();
    end;
}

