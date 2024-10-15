codeunit 144075 "ERM No Taxable VAT"
{
    // 1. Test to verify VAT Entry does not exists for Posted Sales Order with No Taxable VAT.
    // 2. Test to verify VAT Entry does not exists for Posted Sales Credit Memo with No Taxable VAT.
    // 3. Test to verify VAT Entry does not exists for Posted Purchase Order with No Taxable VAT.
    // 4. Test to verify VAT Entry does not exists for Posted Purchase Credit Memo with No Taxable VAT.
    // 5. Test to verify values on Sales Invoice Book report for posted Sales Invoice with VAT Calculation Type as No Taxable VAT.
    // 6. Test to verify values on Sales Invoice Book report for posted Sales Credit Memo with VAT Calculation Type as No Taxable VAT.
    // 7. Test to verify values on Purchase Invoice Book report for posted Purchase Invoice with VAT Calculation Type as No Taxable VAT.
    // 8. Test to verify values on Purchase Invoice Book report for posted Purchase Credit Memo with VAT Calculation Type as No Taxable VAT.
    // 
    // Covers Test Cases for WI - 351894
    // ---------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                 TFS ID
    // ---------------------------------------------------------------------------------------------------------
    // PostSalesOrderWithNoTaxableVAT, PostSalesCreditMemoWithNoTaxableVAT                                282268
    // PostPurchaseOrderWithNoTaxableVAT, PostPurchaseCreditMemoWithNoTaxableVAT                          282269
    // SalesInvoiceBookReportForPostedSalesInvoice, SalesInvoiceBookReportForPostedSalesCreditMemo        282270
    // PurchaseInvoiceBookReportForPostedPurchInvoice, PurchaseInvoiceBookReportForPostedPurchCreditMemo  282271

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [No Taxable VAT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        NotEqualToTxt: Label '<>%1.';
        VATBufferAmountCap: Label 'VATBuffer2_Amount';
        VATBufferBaseAmountCap: Label 'VATBuffer2_Base_VATBuffer2_Amount';
        VATBufferBaseCap: Label 'VATBuffer2_Base';
        VATEntryMustNotExistMsg: Label 'VAT Entry must not exist.';

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithNoTaxableVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Test to verify VAT Entry does not exists for Posted Sales Order with No Taxable VAT.
        PostSalesDocumentWithNoTaxableVAT(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemoWithNoTaxableVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Test to verify VAT Entry does not exists for Posted Sales Credit Memo with No Taxable VAT.
        PostSalesDocumentWithNoTaxableVAT(SalesHeader."Document Type"::"Credit Memo");
    end;

    local procedure PostSalesDocumentWithNoTaxableVAT(DocumentType: Option)
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Setup.
        Initialize;
        FindVATPostingSetupWithNoTaxableVAT(VATPostingSetup);
        CreateSalesDocument(SalesHeader, VATPostingSetup, DocumentType, LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify.
        VerifyNoVATEntryExist(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithNoTaxableVAT()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Test to verify VAT Entry does not exists for Posted Purchase Order with No Taxable VAT.
        PostPurchaseDocumentWithNoTaxableVAT(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemoWithNoTaxableVAT()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Test to verify VAT Entry does not exists for Posted Purchase Credit Memo with No Taxable VAT.
        PostPurchaseDocumentWithNoTaxableVAT(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    local procedure PostPurchaseDocumentWithNoTaxableVAT(DocumentType: Option)
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Setup.
        Initialize;
        FindVATPostingSetupWithNoTaxableVAT(VATPostingSetup);
        CreatePurchaseDocument(PurchaseHeader, VATPostingSetup, DocumentType, LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // Verify.
        VerifyNoVATEntryExist(DocumentNo);
    end;

    [HandlerFunctions('ItemChargeAssignmentSalesModalPageHandler,SalesInvoiceBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceBookReportForPostedSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Sales] [Report]
        // [SCENARIO 293795] Sales Invoice Book report for posted Sales Invoice with VAT Calculation Type as No Taxable VAT.
        Initialize;
        Quantity := LibraryRandom.RandInt(10);
        SalesInvoiceBookReportWithNoTaxableVAT(SalesHeader."Document Type"::Invoice, Quantity, Quantity);
    end;

    [HandlerFunctions('ItemChargeAssignmentSalesModalPageHandler,SalesInvoiceBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceBookReportForPostedSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Sales] [Report]
        // [SCENARIO 293795] Sales Invoice Book report for posted Sales Credit Memo with VAT Calculation Type as No Taxable VAT.
        Initialize;
        Quantity := LibraryRandom.RandInt(10);
        SalesInvoiceBookReportWithNoTaxableVAT(SalesHeader."Document Type"::"Credit Memo", Quantity, -Quantity);
    end;

    local procedure SalesInvoiceBookReportWithNoTaxableVAT(DocumentType: Option; Quantity: Decimal; ExpectedQuantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        Amount: Decimal;
        VATAmount: Decimal;
    begin
        // Setup: Create Sales Document with Normal VAT for Item and Item Charge, No Taxable VAT for G/L Account. Post Sales Document.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesDocument(SalesHeader, VATPostingSetup, DocumentType, Quantity);
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", CreateItemCharge(VATPostingSetup."VAT Prod. Posting Group"), Quantity);
        SalesLine.ShowItemChargeAssgnt;
        CreateSalesLine(
          SalesLine2, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccountWithNoTaxableVAT, LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.
        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue for SalesInvoiceBookRequestPageHandler.
        Amount := ExpectedQuantity * SalesLine."Unit Price";
        VATAmount := Amount * VATPostingSetup."VAT %" / 100;

        // Exercise.
        REPORT.Run(REPORT::"Sales Invoice Book");  // Opens SalesInvoiceBookRequestPageHandler.

        // Verify: Sales Invoice Book report shows Amounts for Item and Item Charge Sales lines and not for G/L Account.
        VerifyXmlValuesOnReport(VATAmount + VATAmount, Amount + Amount, DocumentNo, SalesLine2.Amount);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchModalPageHandler,PurchasesInvoiceBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceBookReportForPostedPurchInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Purchase] [Report]
        // [SCENARIO 293795] Purchase Invoice Book report for posted Purchase Invoice with VAT Calculation Type as No Taxable VAT.
        Initialize;
        Quantity := LibraryRandom.RandInt(10);
        PurchaseInvoiceBookReportWithNoTaxableVAT(PurchaseHeader."Document Type"::Invoice, Quantity, Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchModalPageHandler,PurchasesInvoiceBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceBookReportForPostedPurchCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Purchase] [Report]
        // [SCENARIO 293795] Purchase Invoice Book report for posted Purchase Credit Memo with VAT Calculation Type as No Taxable VAT.
        Initialize;
        Quantity := LibraryRandom.RandInt(10);
        PurchaseInvoiceBookReportWithNoTaxableVAT(PurchaseHeader."Document Type"::"Credit Memo", Quantity, -Quantity);
    end;

    local procedure PurchaseInvoiceBookReportWithNoTaxableVAT(DocumentType: Option; Quantity: Decimal; ExpectedQuantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        Amount: Decimal;
        VATAmount: Decimal;
    begin
        // Setup: Create Purchase Document with Normal VAT for Item and Item Charge, No Taxable VAT for G/L Account. Post Purchase Document.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchaseDocument(PurchaseHeader, VATPostingSetup, DocumentType, Quantity);
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", CreateItemCharge(VATPostingSetup."VAT Prod. Posting Group"),
          Quantity);
        PurchaseLine.ShowItemChargeAssgnt;
        CreatePurchaseLine(
          PurchaseLine2, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccountWithNoTaxableVAT,
          LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.
        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue for PurchasesInvoiceBookRequestPageHandler.
        Amount := ExpectedQuantity * PurchaseLine."Direct Unit Cost";
        VATAmount := Amount * VATPostingSetup."VAT %" / 100;

        // Exercise.
        REPORT.Run(REPORT::"Purchases Invoice Book");  // Opens PurchasesInvoiceBookRequestPageHandler.

        // Verify: Purchases Invoice Book report shows Amounts for Item and Item Charge Purchase lines and not for G/L Account.
        VerifyXmlValuesOnReport(VATAmount + VATAmount, Amount + Amount, DocumentNo, PurchaseLine2.Amount);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
    end;

    local procedure CreateGLAccountWithNoTaxableVAT(): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetupWithNoTaxableVAT(VATPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        GeneralPostingSetup.Validate("COGS Account", GLAccount."No.");
        GeneralPostingSetup.Modify(true);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemCharge(VATProdPostingGroup: Code[20]): Code[20]
    var
        ItemCharge: Record "Item Charge";
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        ItemCharge.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        ItemCharge.Modify(true);
        exit(ItemCharge."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Option; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"), Quantity);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Option; No: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", Quantity);  // Validating Direct Unit Cost as Quantity because value is not important.
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Option; Quantity: Decimal)
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"), Quantity);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Option; No: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Unit Price", Quantity);  // Validating Unit Price as Quantity because value is not important.
        SalesLine.Modify(true);
    end;

    local procedure FindVATPostingSetupWithNoTaxableVAT(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", StrSubstNo(NotEqualToTxt, ''));  // Blank used for Not Equal to Blank filter.
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", StrSubstNo(NotEqualToTxt, ''));  // Blank used for Not Equal to Blank filter.
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");
        VATPostingSetup.FindFirst;
    end;

    local procedure VerifyNoVATEntryExist(DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        Assert.IsFalse(VATEntry.FindFirst, VATEntryMustNotExistMsg);
    end;

    local procedure VerifyXmlValuesOnReport(Amount: Decimal; Base: Decimal; DocumentNo: Code[20]; NoTaxAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(VATBufferAmountCap, Amount);
        LibraryReportDataset.AssertElementWithValueExists(VATBufferBaseCap, Base);
        LibraryReportDataset.AssertElementWithValueExists(VATBufferBaseAmountCap, Base + Amount);
        LibraryReportDataset.AssertElementWithValueExists('DocumentNo_NoTaxableEntry', DocumentNo);
        LibraryReportDataset.AssertElementWithValueExists('Base_NoTaxableEntry', NoTaxAmount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchModalPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.SuggestItemChargeAssignment.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentSalesModalPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        ItemChargeAssignmentSales.SuggestItemChargeAssignment.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchasesInvoiceBookRequestPageHandler(var PurchasesInvoiceBook: TestRequestPage "Purchases Invoice Book")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        PurchasesInvoiceBook.VATEntry.SetFilter("Posting Date", Format(WorkDate));
        PurchasesInvoiceBook.VATEntry.SetFilter("Document No.", DocumentNo);
        PurchasesInvoiceBook.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceBookRequestPageHandler(var SalesInvoiceBook: TestRequestPage "Sales Invoice Book")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        SalesInvoiceBook.VATEntry.SetFilter("Posting Date", Format(WorkDate));
        SalesInvoiceBook.VATEntry.SetFilter("Document No.", DocumentNo);
        SalesInvoiceBook.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

