#if not CLEAN18
codeunit 145008 "Sales Documents"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
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

        isInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RedEntriesFromSalesCorrectionDocuments()
    var
        GLEntry1: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
        SalesHdr: Record "Sales Header";
        SalesLn: Record "Sales Line";
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        SalesInvHdr: Record "Sales Invoice Header";
        PostedDocumentNo: array[2] of Code[20];
    begin
        // 1. Setup
        Initialize;

        // create and post sales invoice
        CreateSalesDocument(SalesHdr, SalesLn, SalesHdr."Document Type"::Invoice);
        PostedDocumentNo[1] := PostSalesDocument(SalesHdr);

        // create and post credit memo from posted sales invoice
        Clear(SalesHdr);
        SalesHdr.Validate("Document Type", SalesHdr."Document Type"::"Credit Memo");
        SalesHdr.Insert(true);
        LibrarySales.CopySalesDocument(SalesHdr, 7, PostedDocumentNo[1], true, false);
        SalesHdr.Get(SalesHdr."Document Type", SalesHdr."No.");
        SalesHdr.Validate("Credit Memo Type", SalesHdr."Credit Memo Type"::"Internal Correction");
        SalesHdr.Validate(Correction, true);
        SalesHdr.Modify(true);

        // 2. Exercise
        PostedDocumentNo[2] := PostSalesDocument(SalesHdr);

        // 3. Verify
        SalesInvHdr.Get(PostedDocumentNo[1]);
        SalesCrMemoHdr.Get(PostedDocumentNo[2]);

        GetGLEntry(GLEntry1, SalesInvHdr."No.", SalesInvHdr."Posting Date");
        GetGLEntry(GLEntry2, SalesCrMemoHdr."No.", SalesCrMemoHdr."Posting Date");

        Assert.IsTrue(
          GLEntry1."G/L Account No." = GLEntry2."G/L Account No.", GLAccMustBeSameErr);
        Assert.IsTrue(
          GLEntry1.Amount + GLEntry2.Amount = 0, OppositeSignErr);
    end;

    local procedure CreateNoSeriesCode(StartingNo: Code[20]; EndingNo: Code[20]): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, StartingNo, EndingNo);
        exit(NoSeries.Code);
    end;

    local procedure CreateSalesDocument(var SalesHdr: Record "Sales Header"; var SalesLn: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    begin
        LibrarySales.CreateSalesHeader(SalesHdr, DocumentType, LibrarySales.CreateCustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLn, SalesHdr, SalesLn.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, 1);
        SalesLn.Validate(Description, SalesHdr."No.");
        SalesLn.Validate("Unit Price", LibraryRandom.RandDec(10000, 2));
        SalesLn.Modify(true);
    end;

    local procedure GetGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; PostingDate: Date)
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.FindFirst;
    end;

    local procedure PostSalesDocument(var SalesHdr: Record "Sales Header"): Code[20]
    begin
        exit(LibrarySales.PostSalesDocument(SalesHdr, true, true));
    end;

    local procedure SetOrderNos(SeriesCode: Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Order Nos." := SeriesCode;
        SalesReceivablesSetup.Modify();
    end;
}
#endif