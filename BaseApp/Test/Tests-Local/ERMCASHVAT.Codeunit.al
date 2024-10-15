codeunit 144110 "ERM CASHVAT"
{
    // Test for feature - CASHVAT.
    // 1. Test to verify CashVAT Product Posting Group on the Purchase - Invoice Report for Purchase Order Posting.
    // 2. Test to verify CashVAT Product Posting Group on the Purchase - Invoice Report for Purchase Invoice Posting.
    // 3. Test to verify CashVAT Product Posting Group updated on the Purchase - Invoice Report successfully for Purchase Order Posting with multiple Purchase Line.
    // 4. Test to verify CashVAT Product Posting Group updated on the Purchase - Invoice Report successfully for Purchase Invoice Posting with multiple Purchase Line.
    // 5. Test to verify CashVAT Product Posting Group on the Purchase - Credit Memo Report for Purchase Credit Memo Posting.
    // 6. Test to verify CashVAT Product Posting Group updated on the Purchase - Credit Memo Report successfully for Purchase Credit Memo Posting with multiple Purchase Line.
    // 7. Test to verify CashVAT Product Posting Group on the Sales - Invoice Report for Sales Order Posting.
    // 8. Test to verify CashVAT Product Posting Group on the Sales - Invoice Report for Sales Invoice Posting.
    // 9. Test to verify CashVAT Product Posting Group updated on the Sales - Invoice Report successfully for Sales Order Posting with multiple Sales Line.
    // 10.Test to verify CashVAT Product Posting Group updated on the Sales - Invoice Report successfully for Sales Invoice Posting with multiple Sales Line.
    // 11.Test to verify CashVAT Product Posting Group on the Sales - Credit Memo Report for Sales Credit Memo Posting.
    // 12.Test to verify CashVAT Product Posting Group updated on the Sales - Credit Memo Report successfully for Sales Credit Memo Posting with multiple Sales Line.
    // 13.Test to verify CashVAT Product Posting Group on the Sales - Invoice Report for Sales Prepayment Invoice Posting.
    // 14.Test to verify CashVAT Product Posting Group updated on the Sales - Invoice Report successfully for Sales Prepayment Invoice Posting with multiple Sales Line.
    // 15.Test to verify CashVAT Product Posting Group on the Sales - Credit Memo Report for Sales Prepayment Credit Memo Posting.
    // 16.Test to verify CashVAT Product Posting Group updated on the Sales - Credit Memo Report successfully for Sales Prepayment Credit Memo Posting with multiple Sales Line.
    // 17.Test to verify CashVAT Product Posting Group updated on the Purchase - Invoice Report successfully for Purchase Prepayment Invoice.
    // 
    //   Covers Test Cases for WI - 346117
    //   ------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                        TFS ID
    //   ------------------------------------------------------------------------------------------------
    //   PostedPurchaseOrderWithCashVATProductPostingGroup                                  155925,155933
    //   PostedPurchaseInvoiceWithCashVATProductPostingGroup                                       155934
    //   PostedPurchaseCrMemoWithCashVATProductPostingGroup                                        155937
    //   PostedSalesOrderWithCashVATProductPostingGroup                                            155927
    //   PostedSalesInvoiceWithCashVATProductPostingGroup                                          155928
    //   PostedSalesCrMemoWithCashVATProductPostingGroup                                           155931
    // 
    //   Covers Test Cases for WI - 346187, 346665
    //   ------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                        TFS ID
    //   ------------------------------------------------------------------------------------------------
    //   PostedMultiLinePurchaseOrderWithCashVAT                                                   155933
    //   PostedMultiLinePurchaseInvoiceWithCashVAT                                                 155935
    //   PostedMultiLinePurchCrMemoWithCashVAT                                                     155937
    //   PostedMultiLineSalesOrderWithCashVAT                                                      155927
    //   PostedMultiLineSalesCrMemoWithCashVAT                                                     155931
    //   PostedMultiLineSalesInvoiceWithCashVAT                                                    155929
    //   PostedSingleLineSalesInvoicePrepaymentWithCashVAT                                         155938
    //   PostedMultiLineSalesInvoicePrepaymentWithCashVAT                                          155939
    //   PostedSingleLineSalesCrMemoPrepaymentWithCashVAT                                   155941,155944
    //   PostedMultiLineSalesCrMemoPrepaymentWithCashVAT                                    155940,155945
    //   PostedPurchaseInvoicePrepaymentWithCashVAT                                         155942,155943

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        CashVATFooterTextCap: Label 'CashVATFooterText';
        VATIdentifierPurchInvLineCap: Label 'VATIdentifier_PurchInvLine';
        VATIdentifierPurchCrMemoLineCap: Label 'VATIdentifier_PurchCrMemoLine';
        VATIdentifierSalesInvLineCap: Label 'VATIdentifier_SalesInvLine';
        VATIdentSalesCrMemoLineCap: Label 'VATIdent_SalesCrMemoLine';
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('PurchaseInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseOrderWithCashVATProductPostingGroup()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test to verify CashVAT Product Posting Group on the Purchase - Invoice Report for Purchase Order Posting.
        PostedPurchaseDocWithCashVATProductPostingGroup(PurchaseHeader."Document Type"::Order, false);  // FALSE for single Purchase Line.
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceWithCashVATProductPostingGroup()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test to verify CashVAT Product Posting Group on the Purchase - Invoice Report for Purchase Invoice Posting.
        PostedPurchaseDocWithCashVATProductPostingGroup(PurchaseHeader."Document Type"::Invoice, false);  // FALSE for single Purchase Line.
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedMultiLinePurchaseOrderWithCashVAT()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test to verify CashVAT Product Posting Group updated on the Purchase - Invoice Report successfully for Purchase Order Posting with multiple Purchase Line.
        PostedPurchaseDocWithCashVATProductPostingGroup(PurchaseHeader."Document Type"::Order, true);  // TRUE for multiple Purchase Line.
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedMultiLinePurchaseInvoiceWithCashVAT()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test to verify CashVAT Product Posting Group updated on the Purchase - Invoice Report successfully for Purchase Invoice Posting with multiple Purchase Line.
        PostedPurchaseDocWithCashVATProductPostingGroup(PurchaseHeader."Document Type"::Invoice, true); // TRUE for multiple Purchase Line.
    end;

    local procedure PostedPurchaseDocWithCashVATProductPostingGroup(DocumentType: Enum "Purchase Document Type"; MultipleLine: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvHeaderNo: Code[20];
        OldCashVATProductPostingGroup: Code[20];
    begin
        // Setup: Update CashVAT Product Posting Group on General Ledger Setup, create and post Purchase Document.
        CreateVATPostingSetup(VATPostingSetup);
        OldCashVATProductPostingGroup := UpdateGLSetupCashVATProductPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        PurchInvHeaderNo := CreateAndPostPurchaseDocument(
            DocumentType, VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."VAT Bus. Posting Group", MultipleLine);

        // Exercise: Run Report Purchase - Invoice.
        RunReportPurchaseInvoice(PurchInvHeaderNo);  // Opens PurchaseInvoiceRequestPageHandler.

        // Verify: Verify CashVAT Product Posting Group is updated on the Footer and VAT Identifier on Report Purchase - Invoice.
        VerifyCashVATAndVATIdentifierOnReport(VATPostingSetup, VATIdentifierPurchInvLineCap);

        // Teardown.
        UpdateGLSetupCashVATProductPostingGroup(OldCashVATProductPostingGroup);
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseCrMemoWithCashVATProductPostingGroup()
    begin
        // Test to verify CashVAT Product Posting Group on the Purchase - Credit Memo Report for Purchase Credit Memo Posting.
        PostedPurchaseCrMemoDocWithCashVATProductPostingGroup(false);  // FALSE for single Purchase Line.
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedMultiLinePurchCrMemoWithCashVAT()
    begin
        // Test to verify CashVAT Product Posting Group updated on the Purchase - Credit Memo Report successfully for Purchase Credit Memo Posting with multiple Purchase Line.
        PostedPurchaseCrMemoDocWithCashVATProductPostingGroup(true);  // TRUE for multiple Purchase Line.
    end;

    local procedure PostedPurchaseCrMemoDocWithCashVATProductPostingGroup(MultipleLine: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchCrMemoHeaderNo: Code[20];
        OldCashVATProductPostingGroup: Code[20];
    begin
        // Setup: Update CashVAT Product Posting Group on General Ledger Setup, create and post Purchase Credit Memo.
        CreateVATPostingSetup(VATPostingSetup);
        OldCashVATProductPostingGroup := UpdateGLSetupCashVATProductPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        PurchCrMemoHeaderNo := CreateAndPostPurchaseDocument(
            PurchaseHeader."Document Type"::"Credit Memo", VATPostingSetup."VAT Prod. Posting Group",
            VATPostingSetup."VAT Bus. Posting Group", MultipleLine);

        // Exercise: Run Report Purchase - Credit Memo.
        RunReportPurchaseCreditMemo(PurchCrMemoHeaderNo);  // Opens PurchaseCreditMemoRequestPageHandler.

        // Verify: Verify CashVAT Product Posting Group is updated on the Footer and VAT Identifier on Report Purchase - Credit Memo.
        VerifyCashVATAndVATIdentifierOnReport(VATPostingSetup, VATIdentifierPurchCrMemoLineCap);

        // Teardown.
        UpdateGLSetupCashVATProductPostingGroup(OldCashVATProductPostingGroup);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesOrderWithCashVATProductPostingGroup()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test to verify CashVAT Product Posting Group on the Sales - Invoice Report for Sales Order Posting.
        PostedSalesDocWithCashVATProductPostingGroup(SalesHeader."Document Type"::Order, false);  // FALSE for single Sales Line.
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceWithCashVATProductPostingGroup()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test to verify CashVAT Product Posting Group on the Sales - Invoice Report for Sales Invoice Posting.
        PostedSalesDocWithCashVATProductPostingGroup(SalesHeader."Document Type"::Invoice, false);  // FALSE for single Sales Line.
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedMultiLineSalesOrderWithCashVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test to verify CashVAT Product Posting Group updated on the Sales - Invoice Report successfully for Sales Order Posting with multiple Sales Line.
        PostedSalesDocWithCashVATProductPostingGroup(SalesHeader."Document Type"::Order, true);  // TRUE for multiple Sales Line.
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedMultiLineSalesInvoiceWithCashVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test to verify CashVAT Product Posting Group updated on the Sales - Invoice Report successfully for Sales Invoice Posting with multiple Sales Line.
        PostedSalesDocWithCashVATProductPostingGroup(SalesHeader."Document Type"::Invoice, true);  // TRUE for multiple Sales Line.
    end;

    local procedure PostedSalesDocWithCashVATProductPostingGroup(DocumentType: Enum "Sales Document Type"; MultipleLine: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvoiceHeaderNo: Code[20];
        OldCashVATProductPostingGroup: Code[20];
    begin
        // Setup: Update CashVAT Product Posting Group on General Ledger Setup, create and post Sales Document.
        CreateVATPostingSetup(VATPostingSetup);
        OldCashVATProductPostingGroup := UpdateGLSetupCashVATProductPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        SalesInvoiceHeaderNo := CreateAndPostSalesDocument(
            DocumentType, VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."VAT Bus. Posting Group", MultipleLine);

        // Exercise: Run Report Sales - Invoice.
        RunReportSalesInvoice(SalesInvoiceHeaderNo);  // Opens SalesInvoiceRequestPageHandler.

        // Verify: Verify CashVAT Product Posting Group is updated on the Footer and VAT Identifier on Report Sales - Invoice.
        VerifyCashVATAndVATIdentifierOnReport(VATPostingSetup, VATIdentifierSalesInvLineCap);

        // Teardown.
        UpdateGLSetupCashVATProductPostingGroup(OldCashVATProductPostingGroup);
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoWithCashVATProductPostingGroup()
    begin
        // Test to verify CashVAT Product Posting Group on the Sales - Credit Memo Report for Sales Credit Memo Posting.
        PostedSalesCrMemoDocWithCashVATProductPostingGroup(false);  // FALSE for single Sales Line.
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedMultiLineSalesCrMemoWithCashVAT()
    begin
        // Test to verify CashVAT Product Posting Group updated on the Sales - Credit Memo Report successfully for Sales Credit Memo Posting with multiple Sales Line.
        PostedSalesCrMemoDocWithCashVATProductPostingGroup(true);  // TRUE for multiple Sales Line.
    end;

    local procedure PostedSalesCrMemoDocWithCashVATProductPostingGroup(MultipleLine: Boolean)
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCrMemoHeaderNo: Code[20];
        OldCashVATProductPostingGroup: Code[20];
    begin
        // Setup: Update CashVAT Product Posting Group on General Ledger Setup, create and post Sales Credit Memo.
        CreateVATPostingSetup(VATPostingSetup);
        OldCashVATProductPostingGroup := UpdateGLSetupCashVATProductPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        SalesCrMemoHeaderNo := CreateAndPostSalesDocument(
            SalesHeader."Document Type"::"Credit Memo", VATPostingSetup."VAT Prod. Posting Group",
            VATPostingSetup."VAT Bus. Posting Group", MultipleLine);

        // Exercise: Run Report Sales - Credit Memo.
        RunReportSalesCreditMemo(SalesCrMemoHeaderNo);  // Opens SalesCreditMemoRequestPageHandler.

        // Verify: Verify CashVAT Product Posting Group is updated on the Footer and VAT Identifier on Report Sales - Credit Memo.
        VerifyCashVATAndVATIdentifierOnReport(VATPostingSetup, VATIdentSalesCrMemoLineCap);

        // Teardown.
        UpdateGLSetupCashVATProductPostingGroup(OldCashVATProductPostingGroup);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSingleLineSalesInvoicePrepaymentWithCashVAT()
    begin
        // Test to verify CashVAT Product Posting Group on the Sales - Invoice Report for Sales Prepayment Invoice Posting.
        PostedSalesInvoicePrepaymentWithCashVATProductPostingGroup(false);  // FALSE for single Sales Line.
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedMultiLineSalesInvoicePrepaymentWithCashVAT()
    begin
        // Test to verify CashVAT Product Posting Group updated on the Sales - Invoice Report successfully for Sales Prepayment Invoice Posting with multiple Sales Line.
        PostedSalesInvoicePrepaymentWithCashVATProductPostingGroup(true);  // TRUE for multiple Sales Line.
    end;

    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    local procedure PostedSalesInvoicePrepaymentWithCashVATProductPostingGroup(MultiLine: Boolean)
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        OldCashVATProductPostingGroup: Code[20];
    begin
        // Setup: Update CashVAT Product Posting Group on General Ledger Setup, create and post Sales Prepayment Invoice.
        CreateVATPostingSetup(VATPostingSetup);
        OldCashVATProductPostingGroup := UpdateGLSetupCashVATProductPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        CreateAndPostSalesInvoicePrepayment(
          SalesHeader, VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."VAT Bus. Posting Group", MultiLine);
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceHeader.FindFirst;
        Commit();  // Commit Required.

        // Exercise: Run Report Sales - Invoice.
        RunReportSalesInvoice(SalesInvoiceHeader."No.");  // Opens SalesInvoiceRequestPageHandler.

        // Verify: Verify CashVAT Product Posting Group is updated on the Footer and VAT Identifier on Report Sales - Invoice.
        VerifyCashVATAndVATIdentifierOnReport(VATPostingSetup, VATIdentifierSalesInvLineCap);

        // Teardown.
        UpdateGLSetupCashVATProductPostingGroup(OldCashVATProductPostingGroup);
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSingleLineSalesCrMemoPrepaymentWithCashVAT()
    begin
        // Test to verify CashVAT Product Posting Group on the Sales - Credit Memo Report for Sales Prepayment Credit Memo Posting.
        PostedSalesCrMemoPrepaymentWithCashVATProductPostingGroup(false);  // FALSE for single Sales Line.
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedMultiLineSalesCrMemoPrepaymentWithCashVAT()
    begin
        // Test to verify CashVAT Product Posting Group updated on the Sales - Credit Memo Report successfully for Sales Prepayment Credit Memo Posting with multiple Sales Line.
        PostedSalesCrMemoPrepaymentWithCashVATProductPostingGroup(true);  // TRUE for multiple Sales Line.
    end;

    local procedure PostedSalesCrMemoPrepaymentWithCashVATProductPostingGroup(MultiLine: Boolean)
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        OldCashVATProductPostingGroup: Code[20];
    begin
        // Setup: Update CashVAT Product Posting Group on General Ledger Setup, create and post Sales Prepayment Credit Memo.
        CreateVATPostingSetup(VATPostingSetup);
        OldCashVATProductPostingGroup := UpdateGLSetupCashVATProductPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        CreateAndPostSalesInvoicePrepayment(
          SalesHeader, VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."VAT Bus. Posting Group", MultiLine);
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesCrMemoHeader.FindFirst;
        Commit();  // Commit Required.

        // Exercise: Run Report Sales - Credit Memo.
        RunReportSalesCreditMemo(SalesCrMemoHeader."No.");  // Opens SalesCreditMemoRequestPageHandler.

        // Verify: Verify CashVAT Product Posting Group is updated on the Footer and VAT Identifier on Report Sales - Credit Memo.
        VerifyCashVATAndVATIdentifierOnReport(VATPostingSetup, VATIdentSalesCrMemoLineCap);

        // Teardown.
        UpdateGLSetupCashVATProductPostingGroup(OldCashVATProductPostingGroup);
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoicePrepaymentWithCashVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        OldCashVATProductPostingGroup: Code[20];
        BuyFromVendorNo: Code[20];
    begin
        // Setup: Update CashVAT Product Posting Group on General Ledger Setup, create and post Purchase Prepayment Invoice.
        CreateVATPostingSetup(VATPostingSetup);
        OldCashVATProductPostingGroup := UpdateGLSetupCashVATProductPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        BuyFromVendorNo := CreateAndPostPurchaseInvoicePrepayment(
            VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchInvHeader.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        PurchInvHeader.FindFirst;
        Commit();  // Commit Required.

        // Exercise: Run Report Purchase - Invoice.
        RunReportPurchaseInvoice(PurchInvHeader."No.");  // Opens PurchaseInvoiceRequestPageHandler.

        // Verify: Verify CashVAT Product Posting Group is updated on the Footer and VAT Identifier on Report Purchase - Invoice.
        VerifyCashVATAndVATIdentifierOnReport(VATPostingSetup, VATIdentifierPurchInvLineCap);

        // Teardown.
        UpdateGLSetupCashVATProductPostingGroup(OldCashVATProductPostingGroup);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        CreateVATPostingSetupWithPrepaymentAccount(VATPostingSetup, VATBusinessPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDec(10, 2));
        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
        exit(Item."No.")
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VATBusPostingGroup: Code[20]; PrepaymentPct: Decimal)
    var
        Vendor: Record Vendor;
        NoSeries: Record "No. Series";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        PurchaseHeader.Validate("Operation Type", FindNoSeries(NoSeries."No. Series Type"::Purchase));
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Prepayment %", PrepaymentPct);
        PurchaseHeader.Validate("Prepayment Due Date", WorkDate);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATProdPostingGroup: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATProdPostingGroup), LibraryRandom.RandDec(10, 2));  // Random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostPurchaseDocument(DocumentType: Enum "Purchase Document Type"; VATProdPostingGroup: Code[20]; VATBusPostingGroup: Code[20]; MultipleLine: Boolean) PostedDocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType, VATBusPostingGroup, 0); // Prepayment % - 0.
        CreatePurchaseLines(PurchaseLine, PurchaseHeader, VATProdPostingGroup, VATBusPostingGroup, MultipleLine);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostPurchaseInvoicePrepayment(VATProdPostingGroup: Code[20]; VATBusPostingGroup: Code[20]) BuyFromVendorNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PrepmtAmtInclVAT: Decimal;
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VATBusPostingGroup, LibraryRandom.RandInt(10)); // Random Prepayment %.
        BuyFromVendorNo := PurchaseHeader."Buy-from Vendor No.";
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, VATProdPostingGroup);
        PrepmtAmtInclVAT :=
          Round(PurchaseLine."Prepmt. Line Amount" + (PurchaseLine."Prepmt. Line Amount" * PurchaseLine."VAT %" / 100));
        PurchaseHeader.Validate("Check Total", PrepmtAmtInclVAT);
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
    end;

    local procedure CreatePurchaseLines(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATProdPostingGroup: Code[20]; VATBusPostingGroup: Code[20]; MultipleLine: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, VATProdPostingGroup);
        if MultipleLine then begin
            CreateVATPostingSetupWithPrepaymentAccount(VATPostingSetup, VATBusPostingGroup);
            CreatePurchaseLine(PurchaseLine, PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group");
        end;
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; VATBusPostingGroup: Code[20]; PrepaymentPct: Decimal)
    var
        Customer: Record Customer;
        NoSeries: Record "No. Series";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        SalesHeader.Validate("Operation Type", FindNoSeries(NoSeries."No. Series Type"::Sales));
        SalesHeader.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        SalesHeader.Validate("Prepayment %", PrepaymentPct);
        SalesHeader.Modify(true);
    end;

    local procedure CreateAndPostSalesDocument(DocumentType: Enum "Sales Document Type"; VATProdPostingGroup: Code[20]; VATBusPostingGroup: Code[20]; MultipleLine: Boolean) PostedDocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, DocumentType, VATBusPostingGroup, 0); // Prepayment % - 0.
        CreateSalesLines(SalesHeader, VATProdPostingGroup, VATBusPostingGroup, MultipleLine);
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostSalesInvoicePrepayment(var SalesHeader: Record "Sales Header"; VATProdPostingGroup: Code[20]; VATBusPostingGroup: Code[20]; MultipleLine: Boolean)
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, VATBusPostingGroup, LibraryRandom.RandDec(10, 2));  // Random Prepayment %.
        CreateSalesLines(SalesHeader, VATProdPostingGroup, VATBusPostingGroup, MultipleLine);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
    end;

    local procedure CreateSalesLines(SalesHeader: Record "Sales Header"; VATProdPostingGroup: Code[20]; VATBusPostingGroup: Code[20]; MultipleLine: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATProdPostingGroup), LibraryRandom.RandDec(10, 2));  // Random Quantity.
        if MultipleLine then begin
            CreateVATPostingSetupWithPrepaymentAccount(VATPostingSetup, VATBusPostingGroup);
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
              LibraryRandom.RandDec(10, 2));  // Random Quantity.
        end;
    end;

    local procedure CreateVATPostingSetupWithPrepaymentAccount(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroup: Code[20])
    var
        VATIdentifier: Record "VAT Identifier";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateVATIdentifier(VATIdentifier);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Identifier", VATIdentifier.Code);
        VATPostingSetup.Validate("Sales Prepayments Account", GLAccount."No.");
        VATPostingSetup.Validate("Purch. Prepayments Account", GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure FindNoSeries(NoSeriesType: Option): Code[20]
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.SetRange("No. Series Type", NoSeriesType);
        NoSeries.SetRange("Date Order", true);
        NoSeries.FindFirst;
        exit(NoSeries.Code);
    end;

    local procedure UpdateGLSetupCashVATProductPostingGroup(NewCashVATProductPostingGroup: Code[20]) OldCashVATProductPostingGroup: Code[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldCashVATProductPostingGroup := GeneralLedgerSetup."CashVAT Product Posting Group";
        GeneralLedgerSetup.Validate("CashVAT Product Posting Group", NewCashVATProductPostingGroup);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure RunReportPurchaseInvoice(No: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseInvoice: Report "Purchase - Invoice";
    begin
        Clear(PurchaseInvoice);
        PurchInvHeader.SetRange("No.", No);
        PurchaseInvoice.SetTableView(PurchInvHeader);
        PurchaseInvoice.Run;
    end;

    local procedure RunReportPurchaseCreditMemo(No: Code[20])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseCreditMemo: Report "Purchase - Credit Memo";
    begin
        Clear(PurchaseCreditMemo);
        PurchCrMemoHdr.SetRange("No.", No);
        PurchaseCreditMemo.SetTableView(PurchCrMemoHdr);
        PurchaseCreditMemo.Run;
    end;

    local procedure RunReportSalesInvoice(No: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoice: Report "Sales - Invoice";
    begin
        Clear(SalesInvoice);
        SalesInvoiceHeader.SetRange("No.", No);
        SalesInvoice.SetTableView(SalesInvoiceHeader);
        SalesInvoice.Run;
    end;

    local procedure RunReportSalesCreditMemo(No: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCreditMemo: Report "Sales - Credit Memo";
    begin
        Clear(SalesCreditMemo);
        SalesCrMemoHeader.SetRange("No.", No);
        SalesCreditMemo.SetTableView(SalesCrMemoHeader);
        SalesCreditMemo.Run;
    end;

    local procedure VerifyCashVATAndVATIdentifierOnReport(VATPostingSetup: Record "VAT Posting Setup"; VATIdentifierCap: Text[1024])
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(CashVATFooterTextCap, VATPostingSetup."VAT Prod. Posting Group");
        LibraryReportDataset.AssertElementWithValueExists(VATIdentifierCap, VATPostingSetup."VAT Identifier");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceRequestPageHandler(var PurchaseInvoice: TestRequestPage "Purchase - Invoice")
    begin
        PurchaseInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoRequestPageHandler(var PurchaseCreditMemo: TestRequestPage "Purchase - Credit Memo")
    begin
        PurchaseCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceRequestPageHandler(var SalesInvoice: TestRequestPage "Sales - Invoice")
    begin
        SalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesCreditMemoRequestPageHandler(var SalesCreditMemo: TestRequestPage "Sales - Credit Memo")
    begin
        SalesCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

