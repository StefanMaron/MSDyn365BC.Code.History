codeunit 134348 "UT Page Actions & Controls - 2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UI]
    end;

    var
        Assert: Codeunit Assert;
        FilterHasBeenChangedErr: Label 'Filter has been changed.';
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicesDrillDowns()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        DetailedCustLedgEntries: TestPage "Detailed Cust. Ledg. Entries";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        PostedDocumentNo: array[3] of Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 315881] "Amount", "Amount Incl. VAT", "Remaining Amount" and "Closed" drilldown is possible on "Posted Sales Invoices" page
        Initialize;

        for Index := 1 to ArrayLen(PostedDocumentNo) do
            PostedDocumentNo[Index] := PostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);

        PostedSalesInvoices.OpenView;
        PostedSalesInvoices.FILTER.SetFilter("No.", GetDocNofilter(PostedDocumentNo));
        PostedSalesInvoices.Next;

        PostedSalesInvoice.Trap;
        PostedSalesInvoices.Amount.DrillDown;
        PostedSalesInvoice."No.".AssertEquals(PostedDocumentNo[2]);
        PostedSalesInvoice.Next;
        PostedSalesInvoice."No.".AssertEquals(PostedDocumentNo[1]);
        PostedSalesInvoice.Close;
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        PostedSalesInvoice.Trap;
        PostedSalesInvoices."Amount Including VAT".DrillDown;
        PostedSalesInvoice."No.".AssertEquals(PostedDocumentNo[2]);
        PostedSalesInvoice.Next;
        PostedSalesInvoice."No.".AssertEquals(PostedDocumentNo[1]);
        PostedSalesInvoice.Close;
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        DetailedCustLedgEntries.Trap;
        PostedSalesInvoices."Remaining Amount".DrillDown;
        DetailedCustLedgEntries.Close;
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        CustomerLedgerEntries.Trap;
        PostedSalesInvoices.Closed.DrillDown;
        CustomerLedgerEntries.Close;
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesCreditMemosDrillDown()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        DetailedCustLedgEntries: TestPage "Detailed Cust. Ledg. Entries";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        PostedDocumentNo: array[3] of Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 315881] "Amount", "Amount Incl. VAT", "Remaining Amount" and "Closed" drilldown is possible on "Posted Sales Credit Memos" page
        Initialize;

        for Index := 1 to ArrayLen(PostedDocumentNo) do
            PostedDocumentNo[Index] := PostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        PostedSalesCreditMemos.OpenView;
        PostedSalesCreditMemos.FILTER.SetFilter("No.", GetDocNofilter(PostedDocumentNo));
        PostedSalesCreditMemos.Next;

        PostedSalesCreditMemo.Trap;
        PostedSalesCreditMemos.Amount.DrillDown;
        PostedSalesCreditMemo."No.".AssertEquals(PostedDocumentNo[2]);
        PostedSalesCreditMemo.Next;
        PostedSalesCreditMemo."No.".AssertEquals(PostedDocumentNo[1]);
        PostedSalesCreditMemo.Close;
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        PostedSalesCreditMemo.Trap;
        PostedSalesCreditMemos."Amount Including VAT".DrillDown;
        PostedSalesCreditMemo."No.".AssertEquals(PostedDocumentNo[2]);
        PostedSalesCreditMemo.Next;
        PostedSalesCreditMemo."No.".AssertEquals(PostedDocumentNo[1]);
        PostedSalesCreditMemo.Close;
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        DetailedCustLedgEntries.Trap;
        PostedSalesCreditMemos."Remaining Amount".DrillDown;
        DetailedCustLedgEntries.Close;
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        CustomerLedgerEntries.Trap;
        PostedSalesCreditMemos.Paid.DrillDown;
        CustomerLedgerEntries.Close;
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedSalesCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoicesDrillDowns()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseInvoices: TestPage "Posted Purchase Invoices";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        DetailedVendorLedgEntries: TestPage "Detailed Vendor Ledg. Entries";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        PostedDocumentNo: array[3] of Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Purchases] [Invoice]
        // [SCENARIO 315881] "Amount", "Amount Incl. VAT", "Remaining Amount" and "Closed" drilldown is possible on "Posted Purchase Invoices" page
        Initialize;

        for Index := 1 to ArrayLen(PostedDocumentNo) do
            PostedDocumentNo[Index] := PostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        PostedPurchaseInvoices.OpenView;
        PostedPurchaseInvoices.FILTER.SetFilter("No.", GetDocNofilter(PostedDocumentNo));
        PostedPurchaseInvoices.Next;

        PostedPurchaseInvoice.Trap;
        PostedPurchaseInvoices.Amount.DrillDown;
        PostedPurchaseInvoice."No.".AssertEquals(PostedDocumentNo[2]);
        PostedPurchaseInvoice.Next;
        PostedPurchaseInvoice."No.".AssertEquals(PostedDocumentNo[1]);
        PostedPurchaseInvoice.Close;
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        PostedPurchaseInvoice.Trap;
        PostedPurchaseInvoices."Amount Including VAT".DrillDown;
        PostedPurchaseInvoice."No.".AssertEquals(PostedDocumentNo[2]);
        PostedPurchaseInvoice.Next;
        PostedPurchaseInvoice."No.".AssertEquals(PostedDocumentNo[1]);
        PostedPurchaseInvoice.Close;
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        DetailedVendorLedgEntries.Trap;
        PostedPurchaseInvoices."Remaining Amount".DrillDown;
        DetailedVendorLedgEntries.Close;
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        VendorLedgerEntries.Trap;
        PostedPurchaseInvoices.Closed.DrillDown;
        VendorLedgerEntries.Close;
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseInvoices.FILTER.GetFilter("No."), FilterHasBeenChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseCreditMemosDrillDown()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseCreditMemos: TestPage "Posted Purchase Credit Memos";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        DetailedVendorLedgEntries: TestPage "Detailed Vendor Ledg. Entries";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        PostedDocumentNo: array[3] of Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Purchases] [Credit Memo]
        // [SCENARIO 315881]"Amount", "Amount Incl. VAT", "Remaining Amount" and "Closed" drilldown is possible on "Posted Purchase Credit Memos" page
        Initialize;

        for Index := 1 to ArrayLen(PostedDocumentNo) do
            PostedDocumentNo[Index] := PostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");

        PostedPurchaseCreditMemos.OpenView;
        PostedPurchaseCreditMemos.FILTER.SetFilter("No.", GetDocNofilter(PostedDocumentNo));
        PostedPurchaseCreditMemos.Next;

        PostedPurchaseCreditMemo.Trap;
        PostedPurchaseCreditMemos.Amount.DrillDown;
        PostedPurchaseCreditMemo."No.".AssertEquals(PostedDocumentNo[2]);
        PostedPurchaseCreditMemo.Next;
        PostedPurchaseCreditMemo."No.".AssertEquals(PostedDocumentNo[1]);
        PostedPurchaseCreditMemo.Close;
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        PostedPurchaseCreditMemo.Trap;
        PostedPurchaseCreditMemos."Amount Including VAT".DrillDown;
        PostedPurchaseCreditMemo."No.".AssertEquals(PostedDocumentNo[2]);
        PostedPurchaseCreditMemo.Next;
        PostedPurchaseCreditMemo."No.".AssertEquals(PostedDocumentNo[1]);
        PostedPurchaseCreditMemo.Close;
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        DetailedVendorLedgEntries.Trap;
        PostedPurchaseCreditMemos."Remaining Amount".DrillDown;
        DetailedVendorLedgEntries.Close;
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);

        VendorLedgerEntries.Trap;
        PostedPurchaseCreditMemos.Paid.DrillDown;
        VendorLedgerEntries.Close;
        Assert.AreEqual(GetDocNofilter(PostedDocumentNo), PostedPurchaseCreditMemos.FILTER.GetFilter("No."), FilterHasBeenChangedErr);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore;

        if IsInitialized then
            exit;

        IsInitialized := true;

        UpdateNoSeriesOnPurchaseSetup;
        UpdateNoSeriesOnSalesSetup;

        LibrarySetupStorage.SaveSalesSetup;
        LibrarySetupStorage.SavePurchasesSetup;
    end;

    local procedure PostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader,
          PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup, LibraryRandom.RandDecInRange(100, 200, 2));
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Option): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader,
          SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, LibraryRandom.RandDecInRange(100, 200, 2));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure GetDocNofilter(DocumentNo: array[3] of Code[20]): Text
    begin
        exit(StrSubstNo('%1..%2', DocumentNo[1], DocumentNo[3]));
    end;

    local procedure UpdateNoSeriesOnSalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup."Return Order Nos." := LibraryERM.CreateNoSeriesCode;
        SalesReceivablesSetup.Modify;
    end;

    local procedure UpdateNoSeriesOnPurchaseSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup."Return Order Nos." := LibraryERM.CreateNoSeriesCode;
        PurchasesPayablesSetup.Modify;
    end;
}

