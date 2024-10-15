codeunit 141002 "VAT Reporting - Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurch: Codeunit "Library - Purchase";
        LibraryInvt: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        Initialized: Boolean;

    local procedure Initialize()
    var
        PurchasesSetup: Record "Purchases & Payables Setup";
        InvtSetup: Record "Inventory Setup";
    begin
        if Initialized then
            exit;

        Initialized := true;
        LibrarySales.SetStockoutWarning(false);
        LibrarySales.SetCreditWarningsToNoWarnings;

        PurchasesSetup.Get;
        PurchasesSetup.Validate("Ext. Doc. No. Mandatory", false);
        PurchasesSetup.Modify;

        LibraryInvt.NoSeriesSetup(InvtSetup);

        Commit;
    end;

    [Test]
    [HandlerFunctions('SalesQuoteRequestHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesQuote_ShowVATSpec()
    var
        SalesHeader: Record "Sales Header";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        AlwaysShowVATSum: Boolean;
    begin
        Initialize;

        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::Quote);
        GetSalesHeaderVATAmt(TempVATAmtLine, SalesHeader);

        for AlwaysShowVATSum := false to true do begin
            // Exercise
            LibraryVariableStorage.Enqueue(AlwaysShowVATSum);
            SalesHeader.SetRecFilter;
            REPORT.Run(REPORT::"Sales - Quote", true, false, SalesHeader);

            // Verify
            VerifyShowVATSpecDataset(AlwaysShowVATSum, TempVATAmtLine, 'VATIdentifier_VATAmtLine');
        end;
    end;

    [Test]
    [HandlerFunctions('SalesOrderConfirmationRequestHandler')]
    [Scope('OnPrem')]
    procedure SalesOrder_ShowVATSpec()
    var
        SalesHeader: Record "Sales Header";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        AlwaysShowVATSum: Boolean;
    begin
        Initialize;

        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::Order);
        GetSalesHeaderVATAmt(TempVATAmtLine, SalesHeader);

        for AlwaysShowVATSum := false to true do begin
            // Exercise
            LibraryVariableStorage.Enqueue(AlwaysShowVATSum);
            SalesHeader.SetRecFilter;
            REPORT.Run(REPORT::"Order Confirmation", true, false, SalesHeader);

            // Verify
            VerifyShowVATSpecDataset(AlwaysShowVATSum, TempVATAmtLine, 'VATAmtLineVATIdentifier');
        end;
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoice_ShowVATSpec()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        AlwaysShowVATSum: Boolean;
    begin
        Initialize;

        CreateSalesInvAndPost(SalesInvoiceHeader);
        GetSalesInvoiceHeaderVATAmt(TempVATAmtLine, SalesInvoiceHeader);

        for AlwaysShowVATSum := false to true do begin
            // Exercise
            LibraryVariableStorage.Enqueue(AlwaysShowVATSum);
            SalesInvoiceHeader.SetRecFilter;
            REPORT.Run(REPORT::"Sales - Invoice", true, false, SalesInvoiceHeader);

            // Verify
            VerifyShowVATSpecDataset(AlwaysShowVATSum, TempVATAmtLine, 'VATAmtLineVATIdentifier');
        end;
    end;

    [Test]
    [HandlerFunctions('SalesCrMemoRequestHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemo_ShowVATSpec()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        AlwaysShowVATSum: Boolean;
    begin
        Initialize;

        CreateSalesCrMemoAndPost(SalesCrMemoHeader);
        GetSalesCrMemoHeaderVATAmt(TempVATAmtLine, SalesCrMemoHeader);

        for AlwaysShowVATSum := false to true do begin
            // Exercise
            LibraryVariableStorage.Enqueue(AlwaysShowVATSum);
            SalesCrMemoHeader.SetRecFilter;
            REPORT.Run(REPORT::"Sales - Credit Memo", true, false, SalesCrMemoHeader);

            // Verify
            VerifyShowVATSpecDataset(AlwaysShowVATSum, TempVATAmtLine, 'VATAmtLineVATIdentifier');
        end;
    end;

    [Test]
    [HandlerFunctions('SalesBlanketOrderRequestHandler')]
    [Scope('OnPrem')]
    procedure SalesBlanketOrder_ShowVATSpec()
    var
        SalesHeader: Record "Sales Header";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        AlwaysShowVATSum: Boolean;
    begin
        Initialize;

        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::"Blanket Order");
        GetSalesHeaderVATAmt(TempVATAmtLine, SalesHeader);

        for AlwaysShowVATSum := false to true do begin
            // Exercise
            LibraryVariableStorage.Enqueue(AlwaysShowVATSum);
            SalesHeader.SetRecFilter;
            REPORT.Run(REPORT::"Blanket Sales Order", true, false, SalesHeader);

            // Verify
            VerifyShowVATSpecDataset(AlwaysShowVATSum, TempVATAmtLine, 'VATAmtLineVATIdentifier');
        end;
    end;

    [Test]
    [HandlerFunctions('SalesQuoteRequestHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesQuote_MultipleVATSpec()
    var
        SalesHeader: Record "Sales Header";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        AlwaysShowVATSum: Boolean;
    begin
        Initialize;

        CreateSalesDocWithMultipleVAT(SalesHeader, SalesHeader."Document Type"::Quote);
        GetSalesHeaderVATAmt(TempVATAmtLine, SalesHeader);

        for AlwaysShowVATSum := false to true do begin
            // Exercise
            LibraryVariableStorage.Enqueue(AlwaysShowVATSum);
            SalesHeader.SetRecFilter;
            REPORT.Run(REPORT::"Sales - Quote", true, false, SalesHeader);

            // Verify
            VerifyShowVATSpecDataset(AlwaysShowVATSum, TempVATAmtLine, 'VATIdentifier_VATAmtLine');
        end;
    end;

    [Test]
    [HandlerFunctions('SalesOrderConfirmationRequestHandler')]
    [Scope('OnPrem')]
    procedure SalesOrder_MultipleVATSpec()
    var
        SalesHeader: Record "Sales Header";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        AlwaysShowVATSum: Boolean;
    begin
        Initialize;

        CreateSalesDocWithMultipleVAT(SalesHeader, SalesHeader."Document Type"::Order);
        GetSalesHeaderVATAmt(TempVATAmtLine, SalesHeader);

        for AlwaysShowVATSum := false to true do begin
            // Exercise
            LibraryVariableStorage.Enqueue(AlwaysShowVATSum);
            SalesHeader.SetRecFilter;
            REPORT.Run(REPORT::"Order Confirmation", true, false, SalesHeader);

            // Verify
            VerifyShowVATSpecDataset(true, TempVATAmtLine, 'VATAmtLineVATIdentifier');
        end;
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoice_MultipleVATSpec()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        AlwaysShowVATSum: Boolean;
    begin
        Initialize;

        CreateSalesInvWithMultipleVATAndPost(SalesInvoiceHeader);
        GetSalesInvoiceHeaderVATAmt(TempVATAmtLine, SalesInvoiceHeader);

        for AlwaysShowVATSum := false to true do begin
            // Exercise
            LibraryVariableStorage.Enqueue(AlwaysShowVATSum);
            SalesInvoiceHeader.SetRecFilter;
            REPORT.Run(REPORT::"Sales - Invoice", true, false, SalesInvoiceHeader);

            // Verify
            VerifyShowVATSpecDataset(true, TempVATAmtLine, 'VATAmtLineVATIdentifier');
        end;
    end;

    [Test]
    [HandlerFunctions('SalesCrMemoRequestHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemo_MultipleVATSpec()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        AlwaysShowVATSum: Boolean;
    begin
        Initialize;

        CreateSalesCrMemoWithMultipleVATAndPost(SalesCrMemoHeader);
        GetSalesCrMemoHeaderVATAmt(TempVATAmtLine, SalesCrMemoHeader);

        for AlwaysShowVATSum := false to true do begin
            // Exercise
            LibraryVariableStorage.Enqueue(AlwaysShowVATSum);
            SalesCrMemoHeader.SetRecFilter;
            REPORT.Run(REPORT::"Sales - Credit Memo", true, false, SalesCrMemoHeader);

            // Verify
            VerifyShowVATSpecDataset(true, TempVATAmtLine, 'VATAmtLineVATIdentifier');
        end;
    end;

    [Test]
    [HandlerFunctions('SalesBlanketOrderRequestHandler')]
    [Scope('OnPrem')]
    procedure SalesBlanketOrder_MultipleVATSpec()
    var
        SalesHeader: Record "Sales Header";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        AlwaysShowVATSum: Boolean;
    begin
        Initialize;

        CreateSalesDocWithMultipleVAT(SalesHeader, SalesHeader."Document Type"::"Blanket Order");
        GetSalesHeaderVATAmt(TempVATAmtLine, SalesHeader);

        for AlwaysShowVATSum := false to true do begin
            // Exercise
            LibraryVariableStorage.Enqueue(AlwaysShowVATSum);
            SalesHeader.SetRecFilter;
            REPORT.Run(REPORT::"Blanket Sales Order", true, false, SalesHeader);

            // Verify
            VerifyShowVATSpecDataset(AlwaysShowVATSum, TempVATAmtLine, 'VATAmtLineVATIdentifier');
        end;
    end;

    [Test]
    [HandlerFunctions('PurchOrderRequestHandler')]
    [Scope('OnPrem')]
    procedure PurchOrder_ShowVATSpec()
    var
        PurchHeader: Record "Purchase Header";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        AlwaysShowVATSum: Boolean;
    begin
        Initialize;

        CreatePurchDoc(PurchHeader, PurchHeader."Document Type"::Order);
        GetPurchHeaderVATAmt(TempVATAmtLine, PurchHeader);

        for AlwaysShowVATSum := false to true do begin
            // Exercise
            LibraryVariableStorage.Enqueue(AlwaysShowVATSum);
            PurchHeader.SetRecFilter;
            REPORT.Run(REPORT::Order, true, false, PurchHeader);

            // Verify
            VerifyShowVATSpecDataset(AlwaysShowVATSum, TempVATAmtLine, 'VATAmtLineVATIdentifier');
        end;
    end;

    [Test]
    [HandlerFunctions('PurchInvoiceRequestHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoice_ShowVATSpec()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        AlwaysShowVATSum: Boolean;
    begin
        Initialize;

        CreatePurchInvAndPost(PurchInvHeader);
        GetPurchInvoiceHeaderVATAmt(TempVATAmtLine, PurchInvHeader);

        for AlwaysShowVATSum := false to true do begin
            // Exercise
            LibraryVariableStorage.Enqueue(AlwaysShowVATSum);
            PurchInvHeader.SetRecFilter;
            REPORT.Run(REPORT::"Purchase - Invoice", true, false, PurchInvHeader);

            // Verify
            VerifyShowVATSpecDataset(AlwaysShowVATSum, TempVATAmtLine, 'VATAmtLineVATIdentifier_VATCounter');
        end;
    end;

    [Test]
    [HandlerFunctions('PurchCrMemoRequestHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemo_ShowVATSpec()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        AlwaysShowVATSum: Boolean;
    begin
        Initialize;

        CreatePurchCrMemoAndPost(PurchCrMemoHdr);
        GetPurchCrMemoHeaderVATAmt(TempVATAmtLine, PurchCrMemoHdr);

        for AlwaysShowVATSum := false to true do begin
            // Exercise
            LibraryVariableStorage.Enqueue(AlwaysShowVATSum);
            PurchCrMemoHdr.SetRecFilter;
            REPORT.Run(REPORT::"Purchase - Credit Memo", true, false, PurchCrMemoHdr);

            // Verify
            VerifyShowVATSpecDataset(AlwaysShowVATSum, TempVATAmtLine, 'VATAmtLineVATIdentifier_VATCounter');
        end;
    end;

    [Test]
    [HandlerFunctions('PurchOrderRequestHandler')]
    [Scope('OnPrem')]
    procedure PurchOrder_MultipleVATSpec()
    var
        PurchHeader: Record "Purchase Header";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        AlwaysShowVATSum: Boolean;
    begin
        Initialize;

        CreatePurchDocWithMultipleVAT(PurchHeader, PurchHeader."Document Type"::Order);
        GetPurchHeaderVATAmt(TempVATAmtLine, PurchHeader);

        for AlwaysShowVATSum := false to true do begin
            // Exercise
            LibraryVariableStorage.Enqueue(AlwaysShowVATSum);
            PurchHeader.SetRecFilter;
            REPORT.Run(REPORT::Order, true, false, PurchHeader);

            // Verify
            VerifyShowVATSpecDataset(AlwaysShowVATSum, TempVATAmtLine, 'VATAmtLineVATIdentifier');
        end;
    end;

    [Test]
    [HandlerFunctions('PurchInvoiceRequestHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoice_MultipleVATSpec()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        AlwaysShowVATSum: Boolean;
    begin
        Initialize;

        CreatePurchInvWithMultipleVATAndPost(PurchInvHeader);
        GetPurchInvoiceHeaderVATAmt(TempVATAmtLine, PurchInvHeader);

        for AlwaysShowVATSum := false to true do begin
            // Exercise
            LibraryVariableStorage.Enqueue(AlwaysShowVATSum);
            PurchInvHeader.SetRecFilter;
            REPORT.Run(REPORT::"Purchase - Invoice", true, false, PurchInvHeader);

            // Verify
            VerifyShowVATSpecDataset(true, TempVATAmtLine, 'VATAmtLineVATIdentifier_VATCounter');
        end;
    end;

    [Test]
    [HandlerFunctions('PurchCrMemoRequestHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemo_MultipleVATSpec()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        AlwaysShowVATSum: Boolean;
    begin
        Initialize;

        CreatePurchCrMemoWithMultipleVATAndPost(PurchCrMemoHdr);
        GetPurchCrMemoHeaderVATAmt(TempVATAmtLine, PurchCrMemoHdr);

        for AlwaysShowVATSum := false to true do begin
            // Exercise
            LibraryVariableStorage.Enqueue(AlwaysShowVATSum);
            PurchCrMemoHdr.SetRecFilter;
            REPORT.Run(REPORT::"Purchase - Credit Memo", true, false, PurchCrMemoHdr);

            // Verify
            VerifyShowVATSpecDataset(true, TempVATAmtLine, 'VATAmtLineVATIdentifier_VATCounter');
        end;
    end;

    [Test]
    [HandlerFunctions('VATReconciliationAHandler')]
    [Scope('OnPrem')]
    procedure SalesVATReconciliationA()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        Month: Integer;
        WD: Date;
    begin
        Initialize;

        WD := WorkDate;

        for Month := 1 to 12 do begin
            WorkDate := DMY2Date(1, Month);

            TempVATAmtLine.Reset;
            if Month in [1, 3, 5, 7, 9, 11] then
                TempVATAmtLine.DeleteAll;

            CreateSalesInvWithMultipleVATAndPost(SalesInvoiceHeader);
            GetSalesInvoiceHeaderVATAmt(TempVATAmtLine, SalesInvoiceHeader);

            SalesInvoiceHeader.SetRecFilter;
            REPORT.Run(REPORT::"VAT Reconciliation A", true, false);

            VerifyVATReconciliation(TempVATAmtLine, true);
        end;

        WorkDate := WD;
    end;

    [Test]
    [HandlerFunctions('VATReconciliationAHandler')]
    [Scope('OnPrem')]
    procedure PurchVATReconciliationA()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        Month: Integer;
        WD: Date;
    begin
        Initialize;

        WD := WorkDate;

        for Month := 1 to 12 do begin
            WorkDate := DMY2Date(1, Month);

            TempVATAmtLine.Reset;
            if Month in [1, 3, 5, 7, 9, 11] then
                TempVATAmtLine.DeleteAll;

            CreatePurchInvWithMultipleVATAndPost(PurchInvHeader);
            GetPurchInvoiceHeaderVATAmt(TempVATAmtLine, PurchInvHeader);

            PurchInvHeader.SetRecFilter;
            REPORT.Run(REPORT::"VAT Reconciliation A", true, false);

            VerifyVATReconciliation(TempVATAmtLine, false);
        end;

        WorkDate := WD;
    end;

    [Test]
    [HandlerFunctions('VATBalancingReportHandler')]
    [Scope('OnPrem')]
    procedure SalesVATBalancingReport()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        Month: Integer;
        WD: Date;
    begin
        Initialize;

        WD := WorkDate;

        for Month := 1 to 12 do begin
            WorkDate := DMY2Date(1, Month);

            TempVATAmtLine.Reset;
            if Month in [1, 3, 5, 7, 9, 11] then
                TempVATAmtLine.DeleteAll;

            CreateSalesInvWithMultipleVATAndPost(SalesInvoiceHeader);
            GetSalesInvoiceHeaderVATAmt(TempVATAmtLine, SalesInvoiceHeader);

            SalesInvoiceHeader.SetRecFilter;
            REPORT.Run(REPORT::"VAT Balancing Report", true, false);

            VerifyVATBalancingReport(TempVATAmtLine, true);
        end;

        WorkDate := WD;
    end;

    [Test]
    [HandlerFunctions('VATBalancingReportHandler')]
    [Scope('OnPrem')]
    procedure PurchVATBalancingReport()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        TempVATAmtLine: Record "VAT Amount Line" temporary;
        Month: Integer;
        WD: Date;
    begin
        Initialize;

        WD := WorkDate;

        for Month := 1 to 12 do begin
            WorkDate := DMY2Date(1, Month);

            TempVATAmtLine.Reset;
            if Month in [1, 3, 5, 7, 9, 11] then
                TempVATAmtLine.DeleteAll;

            CreatePurchInvWithMultipleVATAndPost(PurchInvHeader);
            GetPurchInvoiceHeaderVATAmt(TempVATAmtLine, PurchInvHeader);

            PurchInvHeader.SetRecFilter;
            REPORT.Run(REPORT::"VAT Balancing Report", true, false);

            VerifyVATBalancingReport(TempVATAmtLine, false);
        end;

        WorkDate := WD;
    end;

    local procedure VerifyShowVATSpecDataset(AlwaysShowVATSum: Boolean; var VATAmtLine: Record "VAT Amount Line"; VATId: Text)
    begin
        with LibraryReportDataset do begin
            LoadDataSetFile;
            Reset;
            VATAmtLine.FindFirst;
            repeat
                SetRange(VATId, VATAmtLine."VAT Identifier");
                Assert.AreEqual(AlwaysShowVATSum, GetNextRow, '');
            until VATAmtLine.Next = 0;
        end;
    end;

    local procedure VerifyVATReconciliation(var VATAmtLine: Record "VAT Amount Line"; IsSale: Boolean)
    begin
        with LibraryReportDataset do begin
            LoadDataSetFile;
            VATAmtLine.FindFirst;
            repeat
                Reset;
                SetRange('VATProdPostingGrp_VATPostingSetup', VATAmtLine."VAT Identifier");
                Assert.IsTrue(GetNextRow, '');
                if IsSale then begin
                    AssertCurrentRowValueEquals('VatReceivable', -VATAmtLine."VAT Amount");
                    AssertCurrentRowValueEquals('TurnoverReceivable', -VATAmtLine."VAT Base");
                end else begin
                    AssertCurrentRowValueEquals('VATPayable', VATAmtLine."VAT Amount");
                    AssertCurrentRowValueEquals('TurnoverPayable', VATAmtLine."VAT Base");
                end;
            until VATAmtLine.Next = 0;
        end;
    end;

    local procedure VerifyVATBalancingReport(var VATAmtLine: Record "VAT Amount Line"; IsSale: Boolean)
    begin
        with LibraryReportDataset do begin
            LoadDataSetFile;
            VATAmtLine.FindFirst;
            repeat
                Reset;
                SetRange('VATProdPostingGroup_VATPostingSetup', VATAmtLine."VAT Identifier");
                Assert.IsTrue(GetNextRow, '');
                if IsSale then begin
                    AssertCurrentRowValueEquals('VatReceivable', -VATAmtLine."VAT Amount");
                    AssertCurrentRowValueEquals('TurnoverOut', -VATAmtLine."VAT Base");
                end else begin
                    AssertCurrentRowValueEquals('VatPayableVariance', VATAmtLine."VAT Amount");
                    AssertCurrentRowValueEquals('TurnoverIn', VATAmtLine."VAT Base");
                end;
            until VATAmtLine.Next = 0;
        end;
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; DocType: Option)
    var
        SalesLine: Record "Sales Line";
        Cust: Record Customer;
        Item: Record Item;
    begin
        LibrarySales.CreateCustomer(Cust);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Cust."No.");
        LibraryInvt.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", 10);
        SalesLine.Modify(true);

        Commit;
    end;

    local procedure CreateSalesInvAndPost(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesCrMemoAndPost(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesDocWithMultipleVAT(var SalesHeader: Record "Sales Header"; DocType: Option)
    var
        SalesLine: Record "Sales Line";
        Cust: Record Customer;
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        Lines: Integer;
    begin
        LibrarySales.CreateCustomer(Cust);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Cust."No.");

        for Lines := 1 to 2 do begin
            Clear(Item);
            Clear(VATPostingSetup);
            CreateVATPostingSetup(VATPostingSetup, Cust."VAT Bus. Posting Group");

            LibraryInvt.CreateItem(Item);
            Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            Item.Modify(true);

            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
            SalesLine.Validate("Unit Price", 10);
            SalesLine.Modify(true);
        end;

        Commit;
    end;

    local procedure CreateSalesInvWithMultipleVATAndPost(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocWithMultipleVAT(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesCrMemoWithMultipleVATAndPost(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocWithMultipleVAT(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePurchDoc(var PurchHeader: Record "Purchase Header"; DocType: Option)
    var
        PurchLine: Record "Purchase Line";
        Vend: Record Vendor;
        Item: Record Item;
    begin
        LibraryPurch.CreateVendor(Vend);
        LibraryPurch.CreatePurchHeader(PurchHeader, DocType, Vend."No.");
        LibraryInvt.CreateItem(Item);
        LibraryPurch.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", 1);
        PurchLine.Validate("Direct Unit Cost", 10);
        PurchLine.Modify(true);

        Commit;
    end;

    local procedure CreatePurchInvAndPost(var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchHeader: Record "Purchase Header";
    begin
        CreatePurchDoc(PurchHeader, PurchHeader."Document Type"::Invoice);
        PurchInvHeader.Get(LibraryPurch.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreatePurchCrMemoAndPost(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchHeader: Record "Purchase Header";
    begin
        CreatePurchDoc(PurchHeader, PurchHeader."Document Type"::"Credit Memo");
        PurchCrMemoHdr.Get(LibraryPurch.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreatePurchDocWithMultipleVAT(var PurchHeader: Record "Purchase Header"; DocType: Option)
    var
        PurchLine: Record "Purchase Line";
        Vend: Record Vendor;
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        Lines: Integer;
    begin
        LibraryPurch.CreateVendor(Vend);
        LibraryPurch.CreatePurchHeader(PurchHeader, DocType, Vend."No.");

        for Lines := 1 to 2 do begin
            Clear(Item);
            Clear(VATPostingSetup);
            CreateVATPostingSetup(VATPostingSetup, Vend."VAT Bus. Posting Group");

            LibraryInvt.CreateItem(Item);
            Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            Item.Modify(true);

            LibraryPurch.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", 1);
            PurchLine.Validate("Direct Unit Cost", 10);
            PurchLine.Modify(true);
        end;

        Commit;
    end;

    local procedure CreatePurchInvWithMultipleVATAndPost(var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchHeader: Record "Purchase Header";
    begin
        CreatePurchDocWithMultipleVAT(PurchHeader, PurchHeader."Document Type"::Invoice);
        PurchInvHeader.Get(LibraryPurch.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreatePurchCrMemoWithMultipleVATAndPost(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchHeader: Record "Purchase Header";
    begin
        CreatePurchDocWithMultipleVAT(PurchHeader, PurchHeader."Document Type"::"Credit Memo");
        PurchCrMemoHdr.Get(LibraryPurch.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGrCode: Code[20])
    var
        GLAcc: Record "G/L Account";
        GLAcc2: Record "G/L Account";
        VATProdPostingGr: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateGLAccount(GLAcc);
        LibraryERM.CreateGLAccount(GLAcc2);

        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGr);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGrCode, VATProdPostingGr.Code);
        VATPostingSetup.Validate("VAT Identifier", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT %", 10);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Purchase VAT Account", GLAcc."No.");
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", GLAcc."No.");
        VATPostingSetup.Validate("Sales VAT Account", GLAcc2."No.");
        VATPostingSetup.Validate("Sales VAT Unreal. Account", GLAcc2."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure GetSalesInvoiceHeaderVATAmt(var VATAmtLine: Record "VAT Amount Line"; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if SalesInvoiceLine.FindSet then
            repeat
                with VATAmtLine do begin
                    Init;
                    "VAT Identifier" := SalesInvoiceLine."VAT Identifier";
                    "VAT Calculation Type" := SalesInvoiceLine."VAT Calculation Type";
                    "Tax Group Code" := SalesInvoiceLine."Tax Group Code";

                    "VAT %" := SalesInvoiceLine."VAT %";
                    "VAT Base" := SalesInvoiceLine.Amount;
                    "Amount Including VAT" := SalesInvoiceLine."Amount Including VAT";
                    "Line Amount" := SalesInvoiceLine."Line Amount";

                    InsertLine;
                end;
            until SalesInvoiceLine.Next = 0;
    end;

    local procedure GetSalesCrMemoHeaderVATAmt(var VATAmtLine: Record "VAT Amount Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if SalesCrMemoLine.FindSet then
            repeat
                with VATAmtLine do begin
                    Init;
                    "VAT Identifier" := SalesCrMemoLine."VAT Identifier";
                    "VAT Calculation Type" := SalesCrMemoLine."VAT Calculation Type";
                    "Tax Group Code" := SalesCrMemoLine."Tax Group Code";
                    "Line Amount" := SalesCrMemoLine."Line Amount";

                    "VAT %" := SalesCrMemoLine."VAT %";
                    "VAT Base" := SalesCrMemoLine.Amount;
                    "Amount Including VAT" := SalesCrMemoLine."Amount Including VAT";
                    "Line Amount" := SalesCrMemoLine."Line Amount";

                    InsertLine;
                end;
            until SalesCrMemoLine.Next = 0;
    end;

    local procedure GetSalesHeaderVATAmt(var VATAmtLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet then
            repeat
                with VATAmtLine do begin
                    Init;
                    "VAT Identifier" := SalesLine."VAT Identifier";
                    "VAT Calculation Type" := SalesLine."VAT Calculation Type";
                    "Tax Group Code" := SalesLine."Tax Group Code";

                    "VAT %" := SalesLine."VAT %";
                    "VAT Base" := SalesLine.Amount;
                    "Amount Including VAT" := SalesLine."Amount Including VAT";
                    "Line Amount" := SalesLine."Line Amount";

                    InsertLine;
                end;
            until SalesLine.Next = 0;
    end;

    local procedure GetPurchInvoiceHeaderVATAmt(var VATAmtLine: Record "VAT Amount Line"; PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        if PurchInvLine.FindSet then
            repeat
                with VATAmtLine do begin
                    Init;
                    "VAT Identifier" := PurchInvLine."VAT Identifier";
                    "VAT Calculation Type" := PurchInvLine."VAT Calculation Type";
                    "Tax Group Code" := PurchInvLine."Tax Group Code";
                    "Line Amount" := PurchInvLine."Line Amount";

                    "VAT %" := PurchInvLine."VAT %";
                    "VAT Base" := PurchInvLine.Amount;
                    "Amount Including VAT" := PurchInvLine."Amount Including VAT";
                    "Line Amount" := PurchInvLine."Line Amount";

                    InsertLine;
                end;
            until PurchInvLine.Next = 0;
    end;

    local procedure GetPurchCrMemoHeaderVATAmt(var VATAmtLine: Record "VAT Amount Line"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHdr."No.");
        if PurchCrMemoLine.FindSet then
            repeat
                with VATAmtLine do begin
                    Init;
                    "VAT Identifier" := PurchCrMemoLine."VAT Identifier";
                    "VAT Calculation Type" := PurchCrMemoLine."VAT Calculation Type";
                    "Tax Group Code" := PurchCrMemoLine."Tax Group Code";

                    "VAT %" := PurchCrMemoLine."VAT %";
                    "VAT Base" := PurchCrMemoLine.Amount;
                    "Amount Including VAT" := PurchCrMemoLine."Amount Including VAT";
                    "Line Amount" := PurchCrMemoLine."Line Amount";

                    InsertLine;
                end;
            until PurchCrMemoLine.Next = 0;
    end;

    local procedure GetPurchHeaderVATAmt(var VATAmtLine: Record "VAT Amount Line"; PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        if PurchLine.FindSet then
            repeat
                with VATAmtLine do begin
                    Init;
                    "VAT Identifier" := PurchLine."VAT Identifier";
                    "VAT Calculation Type" := PurchLine."VAT Calculation Type";
                    "Tax Group Code" := PurchLine."Tax Group Code";

                    "VAT %" := PurchLine."VAT %";
                    "VAT Base" := PurchLine.Amount;
                    "Amount Including VAT" := PurchLine."Amount Including VAT";
                    "Line Amount" := PurchLine."Line Amount";

                    InsertLine;
                end;
            until PurchLine.Next = 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesQuoteRequestHandler(var SalesQuote: TestRequestPage "Sales - Quote")
    var
        AlwaysShowVATSum: Variant;
    begin
        LibraryVariableStorage.Dequeue(AlwaysShowVATSum);
        SalesQuote.AlwaysShowVATSum.SetValue := AlwaysShowVATSum;
        SalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderConfirmationRequestHandler(var OrderConfirmation: TestRequestPage "Order Confirmation")
    var
        AlwaysShowVATSum: Variant;
    begin
        LibraryVariableStorage.Dequeue(AlwaysShowVATSum);
        OrderConfirmation.AlwShowVATSum.SetValue := AlwaysShowVATSum;
        OrderConfirmation.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceRequestHandler(var SalesInvoice: TestRequestPage "Sales - Invoice")
    var
        AlwaysShowVATSum: Variant;
    begin
        LibraryVariableStorage.Dequeue(AlwaysShowVATSum);
        SalesInvoice.AlwaysShowVATSum.SetValue := AlwaysShowVATSum;
        SalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesCrMemoRequestHandler(var SalesCrMemo: TestRequestPage "Sales - Credit Memo")
    var
        AlwaysShowVATSum: Variant;
    begin
        LibraryVariableStorage.Dequeue(AlwaysShowVATSum);
        SalesCrMemo.AlwaysShowVATSum.SetValue := AlwaysShowVATSum;
        SalesCrMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderRequestHandler(var BlanketSalesOrder: TestRequestPage "Blanket Sales Order")
    var
        AlwaysShowVATSum: Variant;
    begin
        LibraryVariableStorage.Dequeue(AlwaysShowVATSum);
        BlanketSalesOrder.AlwShowVATSum.SetValue := AlwaysShowVATSum;
        BlanketSalesOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderRequestHandler(var "Order": TestRequestPage "Order")
    var
        AlwaysShowVATSum: Variant;
    begin
        LibraryVariableStorage.Dequeue(AlwaysShowVATSum);
        Order.AlwShowVATSum.SetValue := AlwaysShowVATSum;
        Order.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchInvoiceRequestHandler(var PurchInvoice: TestRequestPage "Purchase - Invoice")
    var
        AlwaysShowVATSum: Variant;
    begin
        LibraryVariableStorage.Dequeue(AlwaysShowVATSum);
        PurchInvoice.AlwShowVATSum.SetValue := AlwaysShowVATSum;
        PurchInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchCrMemoRequestHandler(var PurchCrMemo: TestRequestPage "Purchase - Credit Memo")
    var
        AlwaysShowVATSum: Variant;
    begin
        LibraryVariableStorage.Dequeue(AlwaysShowVATSum);
        PurchCrMemo.AlwShowVATSum.SetValue := AlwaysShowVATSum;
        PurchCrMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATReconciliationAHandler(var VATReconciliationA: TestRequestPage "VAT Reconciliation A")
    var
        VATPeriod: Option Custom,"January-February","March-April","May-June","July-August","September-October","November-December";
    begin
        VATReconciliationA.Year.SetValue := Date2DMY(WorkDate, 3);
        VATPeriod := GetVATReportPeriod;
        VATReconciliationA.Period.SetValue := Format(VATPeriod);
        VATReconciliationA.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATBalancingReportHandler(var VATBalancingReport: TestRequestPage "VAT Balancing Report")
    var
        VATPeriod: Option Custom,"January-February","March-April","May-June","July-August","September-October","November-December";
    begin
        VATBalancingReport.Year.SetValue := Date2DMY(WorkDate, 3);
        VATPeriod := GetVATReportPeriod;
        VATBalancingReport.Period.SetValue := Format(VATPeriod);
        VATBalancingReport.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(QuestionTxt: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    local procedure GetVATReportPeriod(): Integer
    var
        PeriodInt: Integer;
    begin
        PeriodInt := Date2DMY(WorkDate, 2);
        if PeriodInt in [2, 4, 6, 8, 10, 12] then
            PeriodInt := PeriodInt / 2
        else
            PeriodInt := (PeriodInt + 1) / 2;

        exit(PeriodInt);
    end;
}

