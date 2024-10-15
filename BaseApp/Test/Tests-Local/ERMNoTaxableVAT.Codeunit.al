codeunit 144075 "ERM No Taxable VAT"
{
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
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
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

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesModalPageHandler,SalesInvoiceBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceBookReportForPostedSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Sales] [Report]
        // [SCENARIO 293795] Sales Invoice Book report for posted Sales Invoice with VAT Calculation Type as No Taxable VAT.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        SalesInvoiceBookReportWithNoTaxableVAT(
          SalesHeader."Document Type"::Invoice, Quantity, CreateGLAccountWithNoTaxableVAT(), 1);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesModalPageHandler,SalesInvoiceBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceBookReportForPostedSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Sales] [Report]
        // [SCENARIO 293795] Sales Invoice Book report for posted Sales Credit Memo with VAT Calculation Type as No Taxable VAT.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        SalesInvoiceBookReportWithNoTaxableVAT(
          SalesHeader."Document Type"::"Credit Memo", Quantity, CreateGLAccountWithNoTaxableVAT(), -1);
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
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        PurchaseInvoiceBookReportWithNoTaxableVAT(
          PurchaseHeader."Document Type"::Invoice, Quantity, CreateGLAccountWithNoTaxableVAT(), 1);
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
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        PurchaseInvoiceBookReportWithNoTaxableVAT(
          PurchaseHeader."Document Type"::"Credit Memo", Quantity, CreateGLAccountWithNoTaxableVAT(), -1);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesModalPageHandler,SalesInvoiceBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceBookReportNotIn347()
    var
        SalesHeader: Record "Sales Header";
        SalesLineChargeItem: Record "Sales Line";
        SalesLineGLAccount: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Report]
        // [SCENARIO 323351] Sales Invoice Book report does not show No Taxable VAT that ignores in 347 report.

        Initialize();

        // [GIVEN] Posted sales invoice "A" with G/L Account setup of No Taxable VAT and option "Ignore in 347 report" on
        PostSalesDocForNoTaxableScenario(
          DocumentNo, SalesLineChargeItem, SalesLineGLAccount,
          SalesHeader."Document Type"::Invoice, LibraryRandom.RandDec(100, 2), CreateNoTaxGLAccNotIn347Report());
        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue for SalesInvoiceBookRequestPageHandler.

        // [WHEN] Run Sales Invoice Book
        REPORT.Run(REPORT::"Sales Invoice Book");  // Opens SalesInvoiceBookRequestPageHandler.

        // [THEN] No information about posted invoice "A" in the report
        VerifyNoXmlValuesOnReport(DocumentNo, SalesLineGLAccount."Sell-to Customer No.", SalesLineGLAccount.Amount);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchModalPageHandler,PurchasesInvoiceBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceBookReportNotIn347()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineChargeItem: Record "Purchase Line";
        PurchaseLineGLAccount: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Report]
        // [SCENARIO 323351] Purchases Invoice Book report does not show No Taxable VAT that ignores in 347 report.

        Initialize();

        // [GIVEN] Posted purchase invoice "A" with G/L Account setup of No Taxable VAT and option "Ignore in 347 report" on
        PostPurchDocForNoTaxableScenario(
          DocumentNo, PurchaseLineChargeItem, PurchaseLineGLAccount,
          PurchaseHeader."Document Type"::Invoice, LibraryRandom.RandDec(100, 2), CreateNoTaxGLAccNotIn347Report());
        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue for PurchasesInvoiceBookRequestPageHandler.

        // [WHEN] Run Purchases Invoice Book
        REPORT.Run(REPORT::"Purchases Invoice Book");  // Opens PurchasesInvoiceBookRequestPageHandler.

        // [THEN] No information about posted invoice "A" in the report
        VerifyNoXmlValuesOnReport(DocumentNo, PurchaseLineGLAccount."Buy-from Vendor No.", PurchaseLineGLAccount.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntryCreatesIndividuallyForEachPurchInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        NoTaxableEntry: Record "No Taxable Entry";
        PurchSetup: Record "Purchases & Payables Setup";
        NoTaxableEntryCount: Integer;
        DocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 420328] No Taxable Entry creates individually for each posted purchase invoice

        Initialize();

        // [GIVEN] Post first purchase invoice with No Taxable VAT
        FindVATPostingSetupWithNoTaxableVAT(VATPostingSetup);
        CreatePurchaseDocument(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::Invoice, LibraryRandom.RandDec(10, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        NoTaxableEntryCount := NoTaxableEntry.Count();

        // [GIVEN] Set a new No. Series code to the "Posted Invoice Nos." in Purchase Setup to start numeration from the "001" document
        PurchSetup.Get();
        PurchSetup.Validate("Posted Invoice Nos.", CreateNoSeriesCodeWithIntegers());
        PurchSetup.Modify(true);

        // [GIVEN] Create second purchase invoice with No Taxable VAT. Amount in the line is "X"
        CreatePurchaseDocument(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::Invoice, LibraryRandom.RandDec(10, 2));
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);

        // [WHEN] Post second purchase invoice
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Only one additional No Taxable Entry creates with Base = "X"
        Assert.RecordCount(NoTaxableEntry, NoTaxableEntryCount + 1);
        NoTaxableEntry.SetRange("Document No.", DocNo);
        NoTaxableEntry.FindLast();
        NoTaxableEntry.TestField(Base, PurchaseLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntryCreatesIndividuallyForEachPurchCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        NoTaxableEntry: Record "No Taxable Entry";
        PurchSetup: Record "Purchases & Payables Setup";
        NoTaxableEntryCount: Integer;
        DocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 420328] No Taxable Entry creates individually for each posted purchase credit memo

        Initialize();

        // [GIVEN] Post first purchase credit memo with No Taxable VAT
        FindVATPostingSetupWithNoTaxableVAT(VATPostingSetup);
        CreatePurchaseDocument(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::"Credit Memo", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        NoTaxableEntryCount := NoTaxableEntry.Count();

        // [GIVEN] Set a new No. Series code to the "Posted Credit Memo Nos." in Purchase Setup to start numeration from the "001" document
        PurchSetup.Get();
        PurchSetup.Validate("Posted Credit Memo Nos.", CreateNoSeriesCodeWithIntegers());
        PurchSetup.Modify(true);

        // [GIVEN] Create second purchase credit memo with No Taxable VAT. Amount in the line is "X"
        CreatePurchaseDocument(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::"Credit Memo", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);

        // [WHEN] Post second purchase credit memo
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Only one additional No Taxable Entry creates with Base = "X"
        Assert.RecordCount(NoTaxableEntry, NoTaxableEntryCount + 1);
        NoTaxableEntry.SetRange("Document No.", DocNo);
        NoTaxableEntry.FindLast();
        NoTaxableEntry.TestField(Base, -PurchaseLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntryCreatesIndividuallyForEachSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        NoTaxableEntry: Record "No Taxable Entry";
        SalesSetup: Record "Sales & Receivables Setup";
        NoTaxableEntryCount: Integer;
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 420328] No Taxable Entry creates individually for each posted sales invoice

        Initialize();

        // [GIVEN] Post first sales invoice with No Taxable VAT
        FindVATPostingSetupWithNoTaxableVAT(VATPostingSetup);
        CreateSalesDocument(SalesHeader, VATPostingSetup, SalesHeader."Document Type"::Invoice, LibraryRandom.RandDec(10, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        NoTaxableEntryCount := NoTaxableEntry.Count();

        // [GIVEN] Set a new No. Series code to the "Posted Invoice Nos." in Sales Setup to start numeration from the "001" document
        SalesSetup.Get();
        SalesSetup.Validate("Posted Invoice Nos.", CreateNoSeriesCodeWithIntegers());
        SalesSetup.Modify(true);

        // [GIVEN] Create second sales invoice with No Taxable VAT. Amount in the line is "X"
        CreateSalesDocument(SalesHeader, VATPostingSetup, SalesHeader."Document Type"::Invoice, LibraryRandom.RandDec(10, 2));
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);

        // [WHEN] Post second sales invoice
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Only one additional No Taxable Entry creates with Base = "X"
        Assert.RecordCount(NoTaxableEntry, NoTaxableEntryCount + 1);
        NoTaxableEntry.SetRange("Document No.", DocNo);
        NoTaxableEntry.FindLast();
        NoTaxableEntry.TestField(Base, -SalesLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntryCreatesIndividuallyForEachSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        NoTaxableEntry: Record "No Taxable Entry";
        SalesSetup: Record "Sales & Receivables Setup";
        NoTaxableEntryCount: Integer;
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 420328] No Taxable Entry creates individually for each posted sales credit memo

        Initialize();

        // [GIVEN] Post first sales credit memo with No Taxable VAT
        FindVATPostingSetupWithNoTaxableVAT(VATPostingSetup);
        CreateSalesDocument(SalesHeader, VATPostingSetup, SalesHeader."Document Type"::"Credit Memo", LibraryRandom.RandDec(10, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        NoTaxableEntryCount := NoTaxableEntry.Count();

        // [GIVEN] Set a new No. Series code to the "Posted Credit Memo Nos." in Sales Setup to start numeration from the "001" document
        SalesSetup.Get();
        SalesSetup.Validate("Posted Credit Memo Nos.", CreateNoSeriesCodeWithIntegers());
        SalesSetup.Modify(true);

        // [GIVEN] Create second sales credit memo with No Taxable VAT. Amount in the line is "X"
        CreateSalesDocument(SalesHeader, VATPostingSetup, SalesHeader."Document Type"::"Credit Memo", LibraryRandom.RandDec(10, 2));
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);

        // [WHEN] Post second sales credit memo
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Only one additional No Taxable Entry creates with Base = "X"
        Assert.RecordCount(NoTaxableEntry, NoTaxableEntryCount + 1);
        NoTaxableEntry.SetRange("Document No.", DocNo);
        NoTaxableEntry.FindLast();
        NoTaxableEntry.TestField(Base, SalesLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableEntriesPage()
    var
        NoTaxableEntries: TestPage "No Taxable Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 437076] Closed field is accessible on No Taxable Entries Page
        NoTaxableEntries.OpenView();
        Assert.IsTrue(NoTaxableEntries.Closed.Enabled(), '');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.SaveSalesSetup();
        Commit();
        IsInitialized := true;
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

    local procedure CreateNoTaxGLAccNotIn347Report(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(CreateGLAccountWithNoTaxableVAT());
        GLAccount.Validate("Ignore in 347 Report", true);
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

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Purchase Document Type"; Quantity: Decimal)
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

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", Quantity);  // Validating Direct Unit Cost as Quantity because value is not important.
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Sales Document Type"; Quantity: Decimal)
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

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal)
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
        VATPostingSetup.FindFirst();
    end;

    local procedure PostSalesDocumentWithNoTaxableVAT(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Setup.
        Initialize();
        FindVATPostingSetupWithNoTaxableVAT(VATPostingSetup);
        CreateSalesDocument(SalesHeader, VATPostingSetup, DocumentType, LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify.
        VerifyNoVATEntryExist(DocumentNo);
    end;

    local procedure SalesInvoiceBookReportWithNoTaxableVAT(DocumentType: Enum "Sales Document Type"; Quantity: Decimal; GLAccNo: Code[20]; Sign: Integer)
    var
        SalesLineChargeItem: Record "Sales Line";
        SalesLineGLAccount: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        Amount: Decimal;
        VATAmount: Decimal;
    begin
        // Setup: Create Sales Document with Normal VAT for Item and Item Charge, No Taxable VAT for G/L Account. Post Sales Document.
        PostSalesDocForNoTaxableScenario(
          DocumentNo, SalesLineChargeItem, SalesLineGLAccount, DocumentType, Quantity, GLAccNo);
        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue for SalesInvoiceBookRequestPageHandler.
        Amount := Sign * Quantity * SalesLineChargeItem."Unit Price";
        VATPostingSetup.Get(SalesLineChargeItem."VAT Bus. Posting Group", SalesLineChargeItem."VAT Prod. Posting Group");
        VATAmount := Amount * VATPostingSetup."VAT %" / 100;

        // Exercise.
        REPORT.Run(REPORT::"Sales Invoice Book");  // Opens SalesInvoiceBookRequestPageHandler.

        // Verify: Sales Invoice Book report shows Amounts for Item and Item Charge Sales lines and not for G/L Account.
        VerifyXmlValuesOnReport(
          VATAmount + VATAmount, Amount + Amount, DocumentNo,
          SalesLineGLAccount."Sell-to Customer No.", Sign * SalesLineGLAccount.Amount);
    end;

    local procedure PostPurchaseDocumentWithNoTaxableVAT(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Setup.
        Initialize();
        FindVATPostingSetupWithNoTaxableVAT(VATPostingSetup);
        CreatePurchaseDocument(PurchaseHeader, VATPostingSetup, DocumentType, LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // Verify.
        VerifyNoVATEntryExist(DocumentNo);
    end;

    local procedure PurchaseInvoiceBookReportWithNoTaxableVAT(DocumentType: Enum "Purchase Document Type"; Quantity: Decimal; GLAccNo: Code[20]; Sign: Integer)
    var
        PurchaseLineChargeItem: Record "Purchase Line";
        PurchaseLineGLAccount: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        Amount: Decimal;
        VATAmount: Decimal;
    begin
        PostPurchDocForNoTaxableScenario(
          DocumentNo, PurchaseLineChargeItem, PurchaseLineGLAccount, DocumentType, Quantity, GLAccNo);

        LibraryVariableStorage.Enqueue(DocumentNo);  // Enqueue for PurchasesInvoiceBookRequestPageHandler.
        Amount := Sign * Quantity * PurchaseLineChargeItem."Direct Unit Cost";
        VATPostingSetup.Get(PurchaseLineChargeItem."VAT Bus. Posting Group", PurchaseLineChargeItem."VAT Prod. Posting Group");
        VATAmount := Amount * VATPostingSetup."VAT %" / 100;

        // Exercise.
        REPORT.Run(REPORT::"Purchases Invoice Book");  // Opens PurchasesInvoiceBookRequestPageHandler.

        // Verify: Purchases Invoice Book report shows Amounts for Item and Item Charge Purchase lines and not for G/L Account.
        VerifyXmlValuesOnReport(
          VATAmount + VATAmount, Amount + Amount, DocumentNo,
          PurchaseLineGLAccount."Buy-from Vendor No.", Sign * PurchaseLineGLAccount.Amount);
    end;

    local procedure PostSalesDocForNoTaxableScenario(var DocumentNo: Code[20]; var SalesLineChargeItem: Record "Sales Line"; var SalesLineGLAccount: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Quantity: Decimal; GLAccNo: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesDocument(SalesHeader, VATPostingSetup, DocumentType, Quantity);
        CreateSalesLine(
          SalesLineChargeItem, SalesHeader, SalesLineChargeItem.Type::"Charge (Item)",
          CreateItemCharge(VATPostingSetup."VAT Prod. Posting Group"), Quantity);
        SalesLineChargeItem.ShowItemChargeAssgnt();
        CreateSalesLine(
          SalesLineGLAccount, SalesHeader, SalesLineGLAccount.Type::"G/L Account", GLAccNo, LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.
    end;

    local procedure PostPurchDocForNoTaxableScenario(var DocumentNo: Code[20]; var PurchLineChargeItem: Record "Purchase Line"; var PurchLineGLAccount: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; Quantity: Decimal; GLAccNo: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchaseDocument(PurchaseHeader, VATPostingSetup, DocumentType, Quantity);
        CreatePurchaseLine(
          PurchLineChargeItem, PurchaseHeader, PurchLineChargeItem.Type::"Charge (Item)",
          CreateItemCharge(VATPostingSetup."VAT Prod. Posting Group"), Quantity);
        PurchLineChargeItem.ShowItemChargeAssgnt();
        CreatePurchaseLine(
          PurchLineGLAccount, PurchaseHeader, PurchLineGLAccount.Type::"G/L Account", GLAccNo, LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Ship and Invoice.
    end;

    local procedure CreateNoSeriesCodeWithIntegers(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '001', '999');
        exit(NoSeries.Code);
    end;

    local procedure VerifyNoVATEntryExist(DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        Assert.IsFalse(VATEntry.FindFirst(), VATEntryMustNotExistMsg);
    end;

    local procedure VerifyXmlValuesOnReport(Amount: Decimal; Base: Decimal; DocumentNo: Code[20]; SourceNo: Code[20]; NoTaxAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(VATBufferAmountCap, Amount);
        LibraryReportDataset.AssertElementWithValueExists(VATBufferBaseCap, Base);
        LibraryReportDataset.AssertElementWithValueExists(VATBufferBaseAmountCap, Base + Amount);
        LibraryReportDataset.SetRange('SourceNo_NoTaxableEntry', SourceNo);
        LibraryReportDataset.AssertElementWithValueExists('DocumentNo_NoTaxableEntry', DocumentNo);
        LibraryReportDataset.AssertElementWithValueExists('Base_NoTaxableEntry', NoTaxAmount);
    end;

    local procedure VerifyNoXmlValuesOnReport(DocumentNo: Code[20]; SourceNo: Code[20]; NoTaxAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('SourceNo_NoTaxableEntry', SourceNo);
        LibraryReportDataset.AssertElementWithValueNotExist('DocumentNo_NoTaxableEntry', DocumentNo);
        LibraryReportDataset.AssertElementWithValueNotExist('Base_NoTaxableEntry', NoTaxAmount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchModalPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.SuggestItemChargeAssignment.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentSalesModalPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        ItemChargeAssignmentSales.SuggestItemChargeAssignment.Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchasesInvoiceBookRequestPageHandler(var PurchasesInvoiceBook: TestRequestPage "Purchases Invoice Book")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        PurchasesInvoiceBook.VATEntry.SetFilter("Posting Date", Format(WorkDate()));
        PurchasesInvoiceBook.VATEntry.SetFilter("Document No.", DocumentNo);
        PurchasesInvoiceBook."No Taxable Entry".SetFilter("Document No.", DocumentNo);
        PurchasesInvoiceBook.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceBookRequestPageHandler(var SalesInvoiceBook: TestRequestPage "Sales Invoice Book")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        SalesInvoiceBook.VATEntry.SetFilter("Posting Date", Format(WorkDate()));
        SalesInvoiceBook.VATEntry.SetFilter("Document No.", DocumentNo);
        SalesInvoiceBook."No Taxable Entry".SetFilter("Document No.", DocumentNo);
        SalesInvoiceBook.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

