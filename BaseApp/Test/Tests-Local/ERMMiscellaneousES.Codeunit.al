codeunit 144072 "ERM Miscellaneous ES"
{
    //     1. Purpose of this test to verify updates Name, VAT Registration No. in Report 10704 - Sales Invoice Book when Name, VAT Registration No. was set in Service Invoice and not in Customer.
    //     2. Purpose of this test to verify that the report BOM - Raw Materials is displaying the correct output.
    //     3. Purpose of this test to verify the consistence of Vendor Ledger Entries after partial posting of the Purchase Invoice with Payment Discount.
    //     4. Purpose of this test to verify values on Aged Accounts Receivable report after Sales Order posting.
    //     5. Purpose of this test to verify that Amount (LCY) stats and Remaining Amount (LCY) stats are correct in customer ledger entries after reversing payment.
    //     6. Purpose of this test to verify that Amount (LCY) stats and Remaining Amount (LCY) stats are correct in vendor ledger entries after reversing payment.
    //     7. Purpose of this test to verify that Item charge with Line Discount is correctly assigned to Item Cost.
    //  8-11. Purpose of this test to verify that fields in Purchase Line - are updated correctly for Purchase Order,Purchase Invoice,Purchase Credit Memo,Purchase Return Order before release.
    // 12-15. Purpose of this test to verify that fields in Purchase Line - are updated correctly for Purchase Order,Purchase Invoice,Purchase Credit Memo,Purchase Return Order after release.
    //    16. Purpose of this test case to verify that VAT Amount field is correctly updated on Sales Invoice Statistics window when Max. VAT difference allowed" to 0,02.
    //    17. Purpose of this test to verify program populate Profit % field values on 5 decimal places instead of 6 decimal places in Item Card.
    //    18. Purpose of this test to verify values on Official Acc. Summarized Book report with Account Type as Posting.
    //    19. Purpose of this test to verify values on Official Acc. Summarized Book report with Account Type as Heading.
    //    20. Purpose of this test to verify values on Trial Balance report with Account Type as Posting.
    //    21. Purpose of this test to verify values on Trial Balance report with Account Type as Heading.
    //    22. Purpose of this test to verify values on Trial Balance report with Include Closing Entries and Dimension Code.
    //    23. Purpose of this test to verify values on Trial Balance report with Include Closing Entries and without Dimension Code.
    //    24. Purpose of this test to verify that Vendor Ledger Entry can be successfully unapplied.
    //    25. Purpose of this test to verify that Customer Ledger Entry can be successfully unapplied.
    // 
    // Covers Test Cases for WI: 351158
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                           TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // VATRegistrationNoOnSalesInvoiceBookReport                                                                                    301396
    // RawMaterialsOutputOnAssemblyBOMRawMaterialsReport                                                                            152720
    // PurchaseOrderWithPaymentDiscount                                                                                             286017
    // AgedAccountsReceivableReportWithPrintDetails                                                                                 299632
    // ReverseCustomerLedgerEntries                                                                                                 269533
    // ReverseVendorLedgerEntries                                                                                                   269534
    // PurchaseOrderWithLineDiscountOnChargeItem                                                                                    278148
    // 
    // Covers Test Cases for WI: 351898
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                           TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // VATBaseAmountOnPurchaseOrderBeforeReleaseDocument,VATBaseAmountOnPurchaseOrderAfterReleaseDocument                           157240
    // VATBaseAmountOnPurchaseInvoiceBeforeReleaseDocument,VATBaseAmountOnPurchaseInvoiceAfterReleaseDocument                       157241
    // VATBaseAmountOnPurchaseCreditMemoBeforeReleaseDocument,VATBaseAmountOnPurchaseCreditMemoAfterReleaseDocument                 157243
    // VATBaseAmountOnPurchaseReturnOrderBeforeReleaseDocument,VATBaseAmountOnPurchaseReturnOrderAfterReleaseDocument               157242
    // SalesInvoiceWithModifiedVATAmount                                                                                            277576
    // ItemWithProfitPercent                                                                                                        273146
    // 
    // Covers Test Cases for WI: 351315
    // ---------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                           TFS ID
    // ---------------------------------------------------------------------------------------------------------------------------------------
    // OfficialAccSummarizedBookRptWithAccountTypePosting                                                                           152144
    // OfficialAccSummarizedBookRptWithAccountTypeHeading                                                                           152145
    // TrialBalanceReportWithAccountTypeFilterAsPosting, TrialBalanceReportWithAccountTypeFilterAsHeading                           161440
    // TrialBalanceRptWithDimensionCode, TrialBalanceRptWithoutDimensionCode                                                 151065,245832
    // 
    // Covers Test Cases for WI: 352241
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                           TFS ID
    // ----------------------------------------------------------------------------------------------------------------------------------------
    // UnapplyVendorLedgerEntry                                                                                                     152471
    // UnapplyCustomerLedgerEntry                                                                                                   151187

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        CustNoCap: Label 'No_Cust';
        CustomerNameCap: Label 'Customer_Name';
        EntryMustBeOpenMsg: Label 'Entry must be open';
        ExpectedValueMsg: Label 'Amount must be same.';
        FilterTxt: Label '%1..%2';
        GLAccountNoCap: Label 'G_L_Account_No_';
        ItemNoCap: Label 'No_Item';
        ItemInventoryCap: Label 'Inventory_Item';
        OriginalAmtCap: Label 'CLEEndDateRemAmtLCY';
        OriginalAmt2Cap: Label 'AgedCLE2RemAmtLCY';
        PeriodLengthTxt: Label '1M', Comment = '.';
        PrintDetailsCap: Label 'PrintDetails';
        ReverseSignMsg: Label 'Reversed Sign must be TRUE.';
        TotalDebitAmtCap: Label 'TotalDebitAmtAtEnd';
        TotalDebitAmtEndCap: Label 'TotalDebitAmtEnd';
        TotalPeriodCreditAmtCap: Label 'TotalPeriodCreditAmt';
        VATRegistrationNoCap: Label 'Customer__VAT_Registration_No__';
        FieldValueErr: Label 'Wrong value in %1 field';
        PmtDiscAmtErr: Label 'Wrong Payment Discount Amount value';
        GLAccountTypeTxt: Label 'AccountType_GLAccount';
        GLFilterOptionTxt: Label 'GLFilterOption';
        IncorrectCountErr: Label 'Incorrect Count of G/L Entries';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        isInitialized: Boolean;
        PostedInvoiceIsPaidCorrectOrCancelErr: Label 'You cannot perform this action for closed or partially paid entries, nor for any entries that are created with the Cartera module.';

    [Test]
    [HandlerFunctions('SalesInvoiceBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATRegistrationNoOnSalesInvoiceBookReport()
    var
        CompanyInformation: Record "Company Information";
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        DummyVATEntry: Record "VAT Entry";
        LastPostedDocNo: Code[20];
    begin
        // [FEATURE] [Report] [Service] [Sales Invoice Book]
        // Purpose of this test to verify updates Name, VAT Registration No. in Report 10704 - Sales Invoice Book when Name, VAT Registration No. was set in Service Invoice and not in Customer.

        // Setup: Post Service Invoice and Service Credit Memo.
        Initialize();
        CompanyInformation.Get();
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CompanyInformation."Country/Region Code");
        CreateAndPostServiceDocument(
          ServiceLine, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(),
          LibraryInventory.CreateItem(Item), VATRegistrationNoFormat.Format, '');  // Using blank for Corrected Invoice No.
        LastPostedDocNo := CreateAndPostServiceDocument(
            ServiceLine, ServiceHeader."Document Type"::"Credit Memo", ServiceLine."Customer No.",
            ServiceLine."No.", VATRegistrationNoFormat.Format, FindServiceInvoiceHeader(ServiceLine."Customer No."));

        // Exercise.
        RunReportWithVATEntry(REPORT::"Sales Invoice Book", LastPostedDocNo, DummyVATEntry."Document Type"::"Credit Memo");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(CustomerNameCap, ServiceLine."Customer No.");
        LibraryReportDataset.AssertElementWithValueExists(VATRegistrationNoCap, VATRegistrationNoFormat.Format);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExternalDocumentNoOnSalesInvoiceBookReport()
    var
        SalesHeader: Record "Sales Header";
        DummyVATEntry: Record "VAT Entry";
        PostedDocNo: Code[20];
        ExternalDocNo: Text[35];
    begin
        // [FEATURE] [Report] [Sales] [Sales Invoice Book]
        // [SCENARIO 230147] When "Sales Invoice Book" report is run then "External Document No." from Posted Sales Invoice is shown in the corresponding report column
        Initialize();
        ExternalDocNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Posted Sales Invoice with External Document No. = "XX"
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.Validate("External Document No.", ExternalDocNo);
        SalesHeader.Modify(true);
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [WHEN] Run report "Sales Invoice Book"
        RunReportWithVATEntry(REPORT::"Sales Invoice Book", PostedDocNo, DummyVATEntry."Document Type"::Invoice);

        // [THEN] Value "XX" is displayed under Tag <VATEntry2_External_Document_No__> in export XML file
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('VATEntry2_External_Document_No__', ExternalDocNo);
    end;

    [Test]
    [HandlerFunctions('PurchasesInvoiceBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExternalDocumentNoOnPurchasesInvoiceBookReport()
    var
        PurchaseHeader: Record "Purchase Header";
        DummyVATEntry: Record "VAT Entry";
        PostedDocNo: Code[20];
        ExternalDocNo: Text[35];
    begin
        // [FEATURE] [Report] [Purchase] [Purchases Invoice Book]
        // [SCENARIO 230147] When "Purchases Invoice Book" report is run then "Vendor Invoice No." from Posted Purchase Invoice is shown in the corresponding report column
        // [SCENARIO 261472] "Document Date" includes the dataset of the "Purchase Invoice Book" report

        Initialize();
        ExternalDocNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Posted Purchase Invoice with External Document No. = "XX" and "Document Date" = "Y"
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Vendor Invoice No.", ExternalDocNo);
        PurchaseHeader.Validate("Document Date", LibraryRandom.RandDateFrom(WorkDate(), 10));
        PurchaseHeader.Modify(true);
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false);

        // [WHEN] Run report "Purchases Invoice Book"
        RunReportWithVATEntry(REPORT::"Purchases Invoice Book", PostedDocNo, DummyVATEntry."Document Type"::Invoice);

        // [THEN] Value "XX" is displayed under Tag <VATEntry2_External_Document_No__> in export XML file
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('VATEntry2__External_Document_No__', ExternalDocNo);

        // [THEN] Value "Y" is displayed under tag <VATEntry2__Document_Date_> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('VATEntry2__Document_Date_', Format(PurchaseHeader."Document Date"));
    end;

    [Test]
    [HandlerFunctions('AssemblyBOMRawMaterialsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RawMaterialsOutputOnAssemblyBOMRawMaterialsReport()
    var
        Item: Record Item;
    begin
        // Purpose of this test to verify that the report BOM - Raw Materials is displaying the correct output.
        // Setup.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Commit();  // Commit is required.
        LibraryVariableStorage.Enqueue(Item."Base Unit of Measure");  // Enqueue value for AssemblyBOMRawMaterialsRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Assembly BOM - Raw Materials");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ItemNoCap, Item."No.");
        LibraryReportDataset.AssertElementWithValueExists(ItemInventoryCap, Item.Inventory);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithPaymentDiscount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        VendorNo: Code[20];
        PaymentDiscountAmount: Decimal;
    begin
        // [FEATURE] [Post Payment Discount]
        // [SCENARIO] Purpose of this test to verify the CONSISTENSE of Vendor Ledger Entries after partial posting of the Purchase Invoice with Payment Discount.

        // Setup: Post Purchase Order with Payment Discount.
        Initialize();
        VendorNo := CreateVendor();
        GeneralLedgerSetup.Get();
        PurchasesPayablesSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.", 0.000001, 0.05);  // Value required for test case.
        UpdatePurchasesPayablesSetup(true, true);  // Using True for PostPaymentDiscount and AllowVATDifference.
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Order, VendorNo, LibraryRandom.RandDec(10, 2));  // Using Random Value for PaymentDiscountPct.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity / 2);  // Required Partial Quantity To Invoice.
        PurchaseLine.Modify(true);
        CalculateInvAndPmtDiscountsOnPurchaseOrder(PurchaseLine);
        PaymentDiscountAmount :=
          (PurchaseLine."Amount Including VAT" - (PurchaseLine."Amount Including VAT" * PurchaseHeader."Payment Discount %" / 100)) / 2;

        // Exercise.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify.
        VerifyVendorLedgerEntry(PurchaseLine."Buy-from Vendor No.", -Round(PaymentDiscountAmount, LibraryERM.GetAmountRoundingPrecision(), '<'));
    end;

    [Test]
    [HandlerFunctions('AgedAccountsReceivableRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AgedAccountsReceivableReportWithPrintDetails()
    var
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Purpose of this test to verify values on Aged Accounts Receivable report after Sales Order posting.
        // Setup.
        Initialize();
        CreateAndPostSalesDocument(SalesLine, LibrarySales.CreateCustomerNo());
        CreateAndPostSalesDocument(SalesLine2, SalesLine."Sell-to Customer No.");

        // Exercise.
        REPORT.Run(REPORT::"Aged Accounts Receivable");  // Opens AgedAccountsReceivableRequestPageHandler.

        // Verify: Verify values on Aged Accounts Receivable report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(CustNoCap, SalesLine."Sell-to Customer No.");
        LibraryReportDataset.AssertElementWithValueExists(OriginalAmtCap, SalesLine."Amount Including VAT");
        LibraryReportDataset.AssertElementWithValueExists(OriginalAmt2Cap, SalesLine2."Amount Including VAT");
        LibraryReportDataset.AssertElementWithValueExists(PrintDetailsCap, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseCustomerLedgerEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Purpose of this test to verify that Amount (LCY) stats and Remaining Amount (LCY) stats are correct in customer ledger entries after reversing payment.
        // Setup.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        DocumentNo :=
          CreateAndPostGeneralJournalLine(
            GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), -Amount, '', WorkDate());  // Using blank value for ShortcutDimensionOneCode.

        // Exercise.
        ReverseEntry();

        // Verify.
        VerifyReversedCustomerLedgEntry(DocumentNo, -Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseVendorLedgerEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Purpose of this test to verify that Amount (LCY) stats and Remaining Amount (LCY) stats are correct in vendor ledger entries after reversing payment.
        // Setup.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        DocumentNo := CreateAndPostGeneralJournalLine(GenJournalLine."Account Type"::Vendor, CreateVendor(), Amount, '', WorkDate());  // Using blank value for ShortcutDimensionOneCode.

        // Exercise.
        ReverseEntry();

        // Verify.
        VerifyReversedVendorLedgEntry(DocumentNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithLineDiscountOnChargeItem()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        VendorNo: Code[20];
        CostAmountActual: Decimal;
    begin
        // Purpose of this test to verify that Item charge with Line Discount is correctly assigned to Item Cost.

        // Setup: Post Purchase Order with Charge Item.
        Initialize();
        VendorNo := CreateVendor();
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines", GeneralLedgerSetup."Discount Calculation"::" ",
          GeneralLedgerSetup."Unit-Amount Rounding Precision", GeneralLedgerSetup."Max. VAT Difference Allowed");
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Order, VendorNo, LibraryRandom.RandDec(10, 2));  // Using Random Value for PaymentDiscountPct.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Create 2nd Purchase Line for Charge Item, assign Item Charge.
        CreateAndAssignPurchaseLineWithItemCharge(
          PurchaseLine2, PurchaseHeader, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Order,
          PurchaseLine."Document No.", PurchaseLine."Line No.", PurchaseLine."No.");

        CostAmountActual := PurchaseLine.Amount + PurchaseLine2.Amount;

        // Exercise.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify.
        VerifyCostOnItemLedgerEntry(PurchaseLine."No.", CostAmountActual, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithLineDiscountOnChargeAssignedToSalesShipment()
    var
        GLSetup: Record "General Ledger Setup";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        CustomerNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase Invoice] [Posted Shipment] [Item Charge] [Line Discount] [Payment Discount Type]
        // [SCENARIO 382480] When purchase item charge with a discount is assigned to a sales shipment, its cost should be added to the purchased item as non-inventoriable cost, not as actual cost.
        Initialize();

        CustomerNo := LibrarySales.CreateCustomerNo();
        VendorNo := LibraryPurchase.CreateVendorNo();
        GLSetup.Get();
        UpdateGeneralLedgerSetup(
          GLSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines", GLSetup."Discount Calculation"::" ",
          GLSetup."Unit-Amount Rounding Precision", GLSetup."Max. VAT Difference Allowed");

        // [GIVEN] Posted sales order for item "I". Sales Item Ledger Entry = "ILE".
        CreateAndPostSalesDocument(SalesLine, CustomerNo);
        FindSalesShipmentLine(SalesShipmentLine, SalesLine."No.");

        // [GIVEN] Purchase invoice line with item charge assigned to the shipment of item "I". Line amount = "X" minus discount "Y".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        CreateAndAssignPurchaseLineWithItemCharge(
          PurchaseLine, PurchaseHeader, ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Sales Shipment",
          SalesShipmentLine."Document No.", SalesShipmentLine."Line No.", SalesShipmentLine."No.");

        // [WHEN] Post the purchase invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] ILE."Cost Amount (Actual)" = 0.
        // [THEN] ILE."Cost Amount (Non-Invtbl.)" = "X" - "Y".
        VerifyCostOnItemLedgerEntry(SalesLine."No.", 0, -PurchaseLine.Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VATBaseAmountOnPurchaseOrderBeforeReleaseDocument()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of this test to verify that fields in Purchase Line - are updated correctly for Purchase Order before release.
        PurchaseDocumentBeforeRelease(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VATBaseAmountOnPurchaseInvoiceBeforeReleaseDocument()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of this test to verify that fields in Purchase Line - are updated correctly for Purchase Invoice before release.
        PurchaseDocumentBeforeRelease(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VATBaseAmountOnPurchaseCreditMemoBeforeReleaseDocument()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of this test to verify that fields in Purchase Line - are updated correctly for Purchase Credit Memo before release.
        PurchaseDocumentBeforeRelease(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VATBaseAmountOnPurchaseReturnOrderBeforeReleaseDocument()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of this test to verify that fields in Purchase Line - are updated correctly for Purchase Return Order before release.
        PurchaseDocumentBeforeRelease(PurchaseHeader."Document Type"::"Return Order");
    end;

    local procedure PurchaseDocumentBeforeRelease(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup.
        Initialize();

        // Exercise.
        CreatePurchaseDocument(PurchaseLine, DocumentType, CreateVendor(), 0);  // Using 0 for Payment Discount Percent.

        // Verify.
        VerifyPurchaseLine(DocumentType, PurchaseLine."Document No.", PurchaseLine."Line Amount", PurchaseLine."Outstanding Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VATBaseAmountOnPurchaseOrderAfterReleaseDocument()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of this test to verify that fields in Purchase Line - are updated correctly for Purchase Order after release.
        PurchaseDocumentAfterRelease(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VATBaseAmountOnPurchaseInvoiceAfterReleaseDocument()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of this test to verify that fields in Purchase Line - are updated correctly for Purchase Invoice after release.
        PurchaseDocumentAfterRelease(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VATBaseAmountOnPurchaseCreditMemoAfterReleaseDocument()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of this test to verify that fields in Purchase Line - are updated correctly for Purchase Credit Memo after release.
        PurchaseDocumentAfterRelease(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VATBaseAmountOnPurchaseReturnOrderAfterReleaseDocument()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of this test to verify that fields in Purchase Line - are updated correctly for Purchase Return Order after release.
        PurchaseDocumentAfterRelease(PurchaseHeader."Document Type"::"Return Order");
    end;

    local procedure PurchaseDocumentAfterRelease(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, DocumentType, CreateVendor(), 0);  // Using 0 for Payment Discount Percent.
        PurchaseHeader.Get(DocumentType, PurchaseLine."Document No.");

        // Exercise.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // Verify.
        VerifyPurchaseLine(DocumentType, PurchaseHeader."No.", PurchaseLine."Line Amount", PurchaseLine."Outstanding Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsPageHandler,MessageHandler,SalesInvoiceStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithModifiedVATAmount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        VATAmount: Decimal;
        VATDifference: Decimal;
    begin
        // Purpose of this test case to verify that VAT Amount field is correctly updated on Sales Invoice Statistics window when Max. VAT difference allowed" to 0,02.

        // Setup: Create Sales Invoice with multiple line.
        Initialize();
        GeneralLedgerSetup.Get();
        VATDifference := 0.02;  // Value required for test case.
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation",
          GeneralLedgerSetup."Unit-Amount Rounding Precision", VATDifference);
        UpdateSalesReceivablesSetup(true);  // Using True for Allow VAT Difference.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesLine."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccount());
        VATAmount := SalesLine."Amount Including VAT" - SalesLine.Amount - VATDifference;
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue for SalesStatisticsPageHandler.
        OpenVATAmountOnSalesStatistics(SalesHeader."No.");
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue for SalesInvoiceStatisticsPageHandler.

        // Exercise.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // True for Ship and Invoice.

        // Verify: Verification done in SalesInvoiceStatisticsPageHandler.
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.FILTER.SetFilter("No.", SalesHeader."Last Posting No.");
        PostedSalesInvoice.Statistics.Invoke();

        PostedSalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemWithProfitPercent()
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        ProfitPct: Decimal;
    begin
        // Purpose of this test to verify program populate Profit % field values on 5 decimal places instead of 6 decimal places in Item Card.
        // Setup.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandIntInRange(100, 200));
        Item.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
        Item.Modify(true);
        VATPostingSetup.Get(Item."VAT Bus. Posting Gr. (Price)", Item."VAT Prod. Posting Group");

        // Exercise.
        ProfitPct := Round(100 * (1 - Item."Unit Cost" / (Item."Unit Price" / (1 + VATPostingSetup."VAT %" / 100))), 0.00001);  // Value required for testcase.

        // Verify.
        Item.TestField("Profit %", ProfitPct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCountryRegionCodeOnSalesInvoiceWithBillToCustomer()
    var
        CustomerA: Record Customer;
        CustomerB: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [VAT] [Country/Region]
        // [SCENARIO 351578] "VAT Country/Region Code" is taken from "Bill-to Country/Region Code" when "Bill-to Customer No." <> "Sell-to Customer No."
        Initialize();

        // [GIVEN] Customer "A" with "Country/Region Code" = "X"
        // [GIVEN] Customer "B" with "Country/Region Code" = "Y", "Bill-to Customer No." = "A"
        SetupCustomers(CustomerA, CustomerB);

        // [WHEN] Create Sales Order with "Sell-to Customer No." = "B"
        CreateSalesDocument(SalesHeader, CustomerA."No.", '');

        // [THEN] Sales Order has:
        // [THEN] "Sell-to Customer No." = "B"
        // [THEN] "Bill-to Customer No." = "A"
        // [THEN] "Sell-to Country/Region Code" = "Y"
        // [THEN] "Ship-to Country/Region Code" = "Y"
        // [THEN] "Bill-to Country/Region Code" = "X"
        // [THEN] "VAT Country/Region Code" = "X"
        VerifyCountryRegionCode(
          SalesHeader, CustomerA, CustomerB, CustomerA."Country/Region Code", CustomerB."Country/Region Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCountryRegionCodeOnSalesInvoiceWithShipToAddress()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ShipToAddress: Record "Ship-to Address";
    begin
        // [FEATURE] [Sales] [VAT] [Country/Region]
        // [SCENARIO 375654] "VAT Country/Region Code" is taken from "Ship-to Code" info
        Initialize();

        // [GIVEN] Customer "A" with "Country/Region Code" = "X"
        // [GIVEN] Ship-to Address "B" for Customer "A" with "Country/Region Code" = "Y"
        CreateCustomerWithShipToAddress(Customer, ShipToAddress);

        // [WHEN] Create Sales Order with "Sell-to Customer No." = "A", "Ship-to Code" = "A"
        CreateSalesDocument(SalesHeader, Customer."No.", ShipToAddress.Code);

        // [THEN] Sales Order has:
        // [THEN] "Sell-to Customer No." = "A"
        // [THEN] "Bill-to Customer No." = "A"
        // [THEN] "Sell-to Country/Region Code" = "X"
        // [THEN] "Ship-to Country/Region Code" = "Y"
        // [THEN] "Bill-to Country/Region Code" = "X"
        // [THEN] "VAT Country/Region Code" = "Y"
        VerifyCountryRegionCode(
          SalesHeader, Customer, Customer, ShipToAddress."Country/Region Code", ShipToAddress."Country/Region Code");
    end;

    [Test]
    [HandlerFunctions('OfficialAccSummarizedBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OfficialAccSummarizedBookRptWithAccountTypePosting()
    var
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
        AccountType: Option Heading,Posting;
    begin
        // Purpose of this test to verify values on Official Acc. Summarized Book report with Account Type as Posting.
        Initialize();
        GLAccountNo := CreateGLAccountWithAccountType(GLAccount."Account Type"::Posting, '');  // Using blank value for Totaling.
        FindAndUpdateGLAccountWithAccountTypeAsHeading(GLAccountNo);
        OfficialAccSummarizedBookRptWithAccountType(AccountType::Posting, GLAccountNo, GLAccountNo);
    end;

    [Test]
    [HandlerFunctions('OfficialAccSummarizedBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OfficialAccSummarizedBookRptWithAccountTypeHeading()
    var
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
        GLAccountNo2: Code[20];
        AccountType: Option Heading,Posting;
    begin
        // Purpose of this test to verify values on Official Acc. Summarized Book report with Account Type as Heading.
        Initialize();
        GLAccountNo := CreateGLAccountWithAccountType(GLAccount."Account Type"::Posting, '');  // Using blank value for Totaling.
        GLAccountNo2 := FindAndUpdateGLAccountWithAccountTypeAsHeading(GLAccountNo);
        OfficialAccSummarizedBookRptWithAccountType(AccountType::Heading, GLAccountNo, GLAccountNo2);
    end;

    local procedure OfficialAccSummarizedBookRptWithAccountType(AccountType: Option; GLAccountNo: Code[20]; ExpectedGLAccount: Code[20])
    var
        AccountingPeriod: Record "Accounting Period";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Setup.
        Amount := LibraryRandom.RandDec(100, 2);
        AccountingPeriod.FindFirst();
        CreateAndPostGeneralJournalLine(
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount, '', AccountingPeriod."Starting Date");  // Using blank value for ShortcutDimensionOneCode.

        // Enqueue for OfficialAccSummarizedBookRequestPageHandler.
        LibraryVariableStorage.Enqueue(CalcDate('<1Y>', AccountingPeriod."Starting Date"));  // Using 1Y as required for the test case.
        LibraryVariableStorage.Enqueue(AccountType);

        // Exercise.
        REPORT.Run(REPORT::"Official Acc.Summarized Book");  // Opens OfficialAccSummarizedBookRequestPageHandler.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLAccountNoCap, ExpectedGLAccount);
        LibraryReportDataset.AssertElementWithValueExists(TotalDebitAmtEndCap, Amount);
    end;

    [Test]
    [HandlerFunctions('TrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TrialBalanceReportWithAccountTypeFilterAsPosting()
    var
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
        GLAccountNo2: Code[20];
    begin
        // Purpose of this test to verify values on Trial Balance report with Account Type as Posting.
        Initialize();
        GLAccountNo := CreateGLAccountWithAccountType(GLAccount."Account Type"::Posting, '');  // Using blank value for Totaling.
        GLAccountNo2 := CreateGLAccountWithAccountType(GLAccount."Account Type"::Heading, GLAccountNo);
        TrialBalanceReportWithAccountTypeFilter(GLAccountNo, GLAccountNo2, GLAccountNo, GLAccount."Account Type"::Posting, 0); // 0 indicates Posting option of Account Type
    end;

    [Test]
    [HandlerFunctions('TrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TrialBalanceReportWithAccountTypeFilterAsHeading()
    var
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
        GLAccountNo2: Code[20];
    begin
        // Purpose of this test to verify values on Trial Balance report with Account Type as Heading.
        Initialize();
        GLAccountNo := CreateGLAccountWithAccountType(GLAccount."Account Type"::Posting, '');  // Using blank value for Totaling.
        GLAccountNo2 := CreateGLAccountWithAccountType(GLAccount."Account Type"::Heading, GLAccountNo);
        TrialBalanceReportWithAccountTypeFilter(GLAccountNo, GLAccountNo2, GLAccountNo2, GLAccount."Account Type"::Heading, 1); // 1 indicates Heading option of Account Type
    end;

    local procedure TrialBalanceReportWithAccountTypeFilter(GLAccountNo: Code[20]; GLAccountNo2: Code[20]; ExpectedGLAccount: Code[20]; AccountType: Enum "G/L Account Type"; AccountTypeOption: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Setup.
        Amount := LibraryRandom.RandDec(100, 2);
        CreateAndPostGeneralJournalLine(GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount, '', WorkDate());  // Using blank value for ShorcutDimensionOneCode.
        EnqueueValuesForTrialBalanceRequestPageHandler('', StrSubstNo(FilterTxt, GLAccountNo, GLAccountNo2),
          false, false, false, AccountType, WorkDate());  // Using blank value for DepartmentFilter, FALSE for IncludeClosingEntries.

        // Exercise.
        REPORT.Run(REPORT::"Trial Balance");  // Open TrialBalanceRequestPageHandler.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLAccountNoCap, ExpectedGLAccount);
        LibraryReportDataset.AssertElementWithValueExists(TotalDebitAmtCap, Amount);
        LibraryReportDataset.AssertElementWithValueExists(GLAccountTypeTxt, Format(AccountTypeOption));
        LibraryReportDataset.AssertElementWithValueExists(GLFilterOptionTxt, Format(AccountTypeOption));
    end;

    [Test]
    [HandlerFunctions('TrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TrialBalanceRptWithDimensionCode()
    var
        Amount: Decimal;
    begin
        // Purpose of this test to verify values on Trial Balance report with Include Closing Entries and Dimension Code.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        TrialBalanceReportWithIncludeClosingEntries(GetDimensionValueCode(), Amount, 2 * Amount);  // Taking sum of amounts for two entries with Dimension Code.
    end;

    [Test]
    [HandlerFunctions('TrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TrialBalanceRptWithoutDimensionCode()
    var
        Amount: Decimal;
    begin
        // Purpose of this test to verify values on Trial Balance report with Include Closing Entries and without Dimension Code.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        TrialBalanceReportWithIncludeClosingEntries('', Amount, 4 * Amount);  // Using blank value for DepartmentFilter and taking sum of amounts for all the four entries.
    end;

    local procedure TrialBalanceReportWithIncludeClosingEntries(DepartmentFilter: Code[20]; Amount: Decimal; ExpectedAmount: Decimal)
    var
        AccountingPeriod: Record "Accounting Period";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
        PostingDate: Date;
    begin
        // Setup: Post General Journal Lines with different Shortcut Dimension Codes and Posting Date.
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.FindLast();
        PostingDate := CalcDate('<-1D>', AccountingPeriod."Starting Date");  // Using -1D as required for the test case.
        GLAccountNo := CreateGLAccountWithAccountType(GLAccount."Account Type"::Posting, '');  // Using blank value for Totaling.
        CreateAndPostGeneralJournalLine(GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount, '', PostingDate);  // Using blank value for ShortcutDimensionOneCode.
        CreateAndPostGeneralJournalLine(GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount, DepartmentFilter, PostingDate);
        CreateAndPostGeneralJournalLine(
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount, '',
          CalcDate('<' + Format(-LibraryRandom.RandInt(5)) + 'Y>', PostingDate));  // Using blank value for ShortcutDimensionOneCode and random value for Posting Date.
        CreateAndPostGeneralJournalLine(
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount, DepartmentFilter,
          CalcDate('<' + Format(-LibraryRandom.RandInt(5)) + 'Y>', PostingDate));  // Using random value for Posting Date.
        EnqueueValuesForTrialBalanceRequestPageHandler(DepartmentFilter, GLAccountNo,
          true, false, false, GLAccount."Account Type"::Posting, PostingDate);  // Using TRUE for IncludeClosingEntries.

        // Exercise.
        REPORT.Run(REPORT::"Trial Balance");  // Oepns TrialBalanceRequestPageHandler.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TotalPeriodCreditAmtCap, ExpectedAmount);
        LibraryReportDataset.AssertElementWithValueExists(GLAccountNoCap, GLAccountNo);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler,MessageHandler,PostApplicationModalPageHandler,UnapplyVendorEntriesModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UnapplyVendorLedgerEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        DocumentNo: Code[20];
        OldOpenStatus: Boolean;
    begin
        // [FEATURE] [Purchase] [Unapply]
        // [SCENARIO] Unapply Payment Vendor Ledger Entry from simple Invoice

        // [GIVEN] Create and post Purchase Invoice, Create and post Gen Journal Line. Apply Vendor Ledger Entry.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Invoice, CreateVendor(), 0);  // Using 0 for PaymentDiscountPct.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Ship and Invoice.
        DocumentNo :=
          CreateAndPostGeneralJournalLine(
            GenJournalLine."Account Type"::Vendor, PurchaseLine."Buy-from Vendor No.", PurchaseLine."Amount Including VAT", '', WorkDate());  // Blank for Shortcut Dimension 1 Code.
        ApplyVendorLedgerEntry(VendorLedgerEntries, DocumentNo);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, DocumentNo);
        OldOpenStatus := VendorLedgerEntry.Open;

        // [WHEN] Unapply Payment
        VendorLedgerEntries.UnapplyEntries.Invoke();  // Invokes UnapplyVendorEntriesModalPageHandler.

        // [THEN] Vendor Ledger Entry is successfully unapplied.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, DocumentNo);
        VendorLedgerEntry.CalcFields(Amount);
        VendorLedgerEntry.TestField(Open, true);
        Assert.IsFalse(VendorLedgerEntry.Open = OldOpenStatus, EntryMustBeOpenMsg);
        Assert.AreEqual(PurchaseLine."Amount Including VAT", VendorLedgerEntry.Amount, ExpectedValueMsg);

        // [THEN] Two G/L Entries are posted to the same account VendorPostingGroup."Payables Account"
        VerifyVendGLUnapplication(VendorLedgerEntry."Vendor No.", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler,PostApplicationModalPageHandler,MessageHandler,UnapplyCustomerEntriesModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UnapplyCustomerLedgerEntry()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        DocumentNo: Code[20];
        OldOpenStatus: Boolean;
    begin
        // [FEATURE] [Sales] [Unapply]
        // [SCENARIO] Unapply Payment Customer Ledger Entry from simple Invoice

        // [GIVEN] Create and post Sales Invoice, Create and post Gen Journal Line. Apply Customer Ledger Entry.
        Initialize();
        CreateAndPostSalesDocument(SalesLine, LibrarySales.CreateCustomerNo());
        DocumentNo :=
          CreateAndPostGeneralJournalLine(
            GenJournalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.", -SalesLine."Amount Including VAT", '', WorkDate());  // Blank for Shortcut Dimension 1 Code.
        ApplyCustomerLedgerEntry(CustomerLedgerEntries, DocumentNo);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        OldOpenStatus := CustLedgerEntry.Open;

        // [WHEN] Unapply Payment
        CustomerLedgerEntries.UnapplyEntries.Invoke();  // Invokes UnapplyCustomerEntriesModalPageHandler.

        // [THEN] Customer Ledger Entry is successfully unapplied.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        CustLedgerEntry.CalcFields(Amount);
        CustLedgerEntry.TestField(Open, true);
        Assert.IsFalse(CustLedgerEntry.Open = OldOpenStatus, EntryMustBeOpenMsg);
        Assert.AreEqual(-SalesLine."Amount Including VAT", CustLedgerEntry.Amount, ExpectedValueMsg);

        // [THEN] Two G/L Entries are posted to the same account CustomerPostingGroup."Receivables Account"
        VerifyCustGLUnapplication(CustLedgerEntry."Customer No.", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PmtDiscountAfterCopyPostedPurchDoc()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        NewPurchaseHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
    begin
        // [SCENARIO] Check Pmt. Discount amount on Purchase Credit Memo after CopyDocument function
        Initialize();
        VendorNo := CreateVendor();
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.", 0.000001, 0.05);  // Value required for test case.

        // [GIVEN] Create and Post Purchase Order with random Pmt. Discount
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Order, VendorNo, LibraryRandom.RandDec(10, 2));
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CalculateInvAndPmtDiscountsOnPurchaseOrder(PurchaseLine);
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create a new Purchase Credit Memo
        LibraryPurchase.CreatePurchHeader(NewPurchaseHeader, NewPurchaseHeader."Document Type"::"Credit Memo", VendorNo);

        // [WHEN] Run Copy Document on new Credit Memo and use posted Invoice
        CopyDocumentMgt.CopyPurchDoc("Purchase Document Type From"::"Posted Invoice", PostedDocNo, NewPurchaseHeader);

        // [THEN] Pmt. Discount amount are equal on new and copied-from documents
        Assert.AreEqual(
          CalcPostedPurchInvPmtDiscAmt(PostedDocNo),
          CalcPurchDocPmtDiscAmt(NewPurchaseHeader."No."),
          PmtDiscAmtErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PmtDiscountAfterCopyPostedSalesDoc()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        NewSalesHeader: Record "Sales Header";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        CustomerNo: Code[20];
        PostedDocNo: Code[20];
    begin
        // [SCENARIO] Check Pmt. Discount amount on Sales Credit Memo after CopyDocument function
        Initialize();
        CustomerNo := LibrarySales.CreateCustomerNo();
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.", 0.000001, 0.05);  // Value required for test case.

        // [GIVEN] Create and Post Sales Order with random Pmt. Discount
        PostedDocNo := CreatePostSalesDocWithPmtDisc(CustomerNo);

        // [GIVEN] Create a new Sales Credit Memo
        LibrarySales.CreateSalesHeader(NewSalesHeader, NewSalesHeader."Document Type"::"Credit Memo", CustomerNo);

        // [WHEN] Run Copy Document on new Credit Memo and use posted Invoice
        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::"Posted Invoice", PostedDocNo, NewSalesHeader);

        // [THEN] Pmt. Discount amount are equal on new and copied-from documents
        Assert.AreEqual(
          CalcPostedSalesInvPmtDiscAmt(PostedDocNo),
          CalcSalesDocPmtDiscAmt(NewSalesHeader."No."),
          PmtDiscAmtErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestVendorPmtAfterPrepmtWithoutPreferredBankAcc()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Vendor Bank Account] [Suggest Vendor Payments]
        // [SCENARIO 380970] Suggest vendor payments after posted order with prepayment in case of blank Vendor."Preferred Bank Account Code"
        Initialize();

        // [GIVEN] Vendor with "Preferred Bank Account Code" = ""
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] Purchase Order with prepayment percent. PurchaseHeader."Vendor Bank Acc. Code" has default value "" from vendor card.
        CreatePurchaseOrderWithPrepmtPct(PurchaseHeader, VendorNo);
        // [GIVEN] Post Prepayment Invoice. Post Order.
        PostPurchasePrepaymentInvoiceAndOrder(PurchaseHeader);

        // [WHEN] Suggest vendor payments
        RunSuggestVendorPayments(GenJournalLine, VendorNo);

        // [THEN] There are two lines have been suggested in the payment journal, both with "Recipient Bank Account" = ""
        // [THEN] Posted vendor documents (prepayment, invoice) have "Vendor Bank Acc. Code" = ""
        // [THEN] Vendor ledger entries (prepayment, invoice) have "Recipient Bank Account" = ""
        VerifyVendorRecipientBankAccAfterPrepmtAndSuggestPayments(GenJournalLine, VendorNo, '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestVendorPmtAfterPrepmtWithPreferredBankAcc()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        VendorPreferredBankAccountCode: Code[20];
    begin
        // [FEATURE] [Purchase] [Vendor Bank Account] [Suggest Vendor Payments]
        // [SCENARIO 380970] Suggest vendor payments after posted order with prepayment in case of Vendor."Preferred Bank Account Code"
        Initialize();

        // [GIVEN] Vendor with "Preferred Bank Account Code" = "A"
        VendorNo := CreateVendorWithPreferredBankAccount(VendorPreferredBankAccountCode);
        // [GIVEN] Purchase Order with prepayment percent. PurchaseHeader."Vendor Bank Acc. Code" has default value "A" from vendor card.
        CreatePurchaseOrderWithPrepmtPct(PurchaseHeader, VendorNo);
        // [GIVEN] Post Prepayment Invoice. Post Order.
        PostPurchasePrepaymentInvoiceAndOrder(PurchaseHeader);

        // [WHEN] Suggest vendor payments
        RunSuggestVendorPayments(GenJournalLine, VendorNo);

        // [THEN] There are two lines have been suggested in the payment journal, both with "Recipient Bank Account" = "A"
        // [THEN] Posted vendor documents (prepayment, invoice) have "Vendor Bank Acc. Code" = "A"
        // [THEN] Vendor ledger entries (prepayment, invoice) have "Recipient Bank Account" = "A"
        VerifyVendorRecipientBankAccAfterPrepmtAndSuggestPayments(
          GenJournalLine, VendorNo, VendorPreferredBankAccountCode, VendorPreferredBankAccountCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestVendorPmtAfterPrepmtWithoutPreferredBankAccAndModifyHeaderVendBankAcc()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Vendor Bank Account] [Suggest Vendor Payments]
        // [SCENARIO 380970] Suggest vendor payments after posted order with prepayment in case of blank Vendor."Preferred Bank Account Code" and PurchaseHeader."Vendor Bank Acc. Code"
        Initialize();

        // [GIVEN] Vendor with "Preferred Bank Account Code" = ""
        VendorNo := LibraryPurchase.CreateVendorNo();
        // [GIVEN] Purchase Order with prepayment percent. Change PurchaseHeader."Vendor Bank Acc. Code" = "B"
        CreatePurchaseOrderWithPrepmtPct(PurchaseHeader, VendorNo);
        // [GIVEN] Post Prepayment Invoice. Post Order.
        PostPurchasePrepaymentInvoiceAndOrder(PurchaseHeader);

        // [WHEN] Suggest vendor payments
        RunSuggestVendorPayments(GenJournalLine, VendorNo);

        // [THEN] There are two lines have been suggested in the payment journal, both with "Recipient Bank Account" = "B"
        // [THEN] Posted vendor documents (prepayment, invoice) have "Vendor Bank Acc. Code" = "B"
        // [THEN] Vendor ledger entries (prepayment, invoice) have "Recipient Bank Account" = "B"
        VerifyVendorRecipientBankAccAfterPrepmtAndSuggestPayments(
          GenJournalLine, VendorNo, PurchaseHeader."Vendor Bank Acc. Code", PurchaseHeader."Vendor Bank Acc. Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestVendorPmtAfterPrepmtWithPreferredBankAccAndBlankHeaderVendBankAcc()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        VendorPreferredBankAccountCode: Code[20];
    begin
        // [FEATURE] [Purchase] [Vendor Bank Account] [Suggest Vendor Payments]
        // [SCENARIO 380970] Suggest vendor payments after posted order with prepayment in case of Vendor."Preferred Bank Account Code" and blank PurchaseHeader."Vendor Bank Acc. Code"
        Initialize();

        // [GIVEN] Vendor with "Preferred Bank Account Code" = "A"
        VendorNo := CreateVendorWithPreferredBankAccount(VendorPreferredBankAccountCode);
        // [GIVEN] Purchase Order with prepayment percent. Change PurchaseHeader."Vendor Bank Acc. Code" = ""
        CreatePurchaseOrderWithPrepmtPct(PurchaseHeader, VendorNo);
        UpdatePurchaseHeaderVendorBankAccCode(PurchaseHeader, '');
        // [GIVEN] Post Prepayment Invoice. Post Order.
        PostPurchasePrepaymentInvoiceAndOrder(PurchaseHeader);

        // [WHEN] Suggest vendor payments
        RunSuggestVendorPayments(GenJournalLine, VendorNo);

        // [THEN] There are two lines have been suggested in the payment journal, both with "Recipient Bank Account" = "A"
        // [THEN] Posted vendor documents (prepayment, invoice) have "Vendor Bank Acc. Code" = ""
        // [THEN] Vendor ledger entries (prepayment, invoice) have "Recipient Bank Account" = ""
        VerifyVendorRecipientBankAccAfterPrepmtAndSuggestPayments(
          GenJournalLine, VendorNo, VendorPreferredBankAccountCode, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestVendorPmtAfterPrepmtWithPreferredBankAccAndModifyHeaderVendBankAcc()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        VendorPreferredBankAccountCode: Code[20];
    begin
        // [FEATURE] [Purchase] [Vendor Bank Account] [Suggest Vendor Payments]
        // [SCENARIO 380970] Suggest vendor payments after posted order with prepayment in case of Vendor."Preferred Bank Account Code" and changed PurchaseHeader."Vendor Bank Acc. Code"
        Initialize();

        // [GIVEN] Vendor with "Preferred Bank Account Code" = "A"
        VendorNo := CreateVendorWithPreferredBankAccount(VendorPreferredBankAccountCode);
        // [GIVEN] Purchase Order with prepayment percent. Change PurchaseHeader."Vendor Bank Acc. Code" = "B"
        CreatePurchaseOrderWithPrepmtPct(PurchaseHeader, VendorNo);
        UpdatePurchaseHeaderVendorBankAccCode(PurchaseHeader, CreateVendorBankAccountNo(VendorNo));
        // [GIVEN] Post Prepayment Invoice. Post Order.
        PostPurchasePrepaymentInvoiceAndOrder(PurchaseHeader);

        // [WHEN] Suggest vendor payments
        RunSuggestVendorPayments(GenJournalLine, VendorNo);

        // [THEN] There are two lines have been suggested in the payment journal, both with "Recipient Bank Account" = "B"
        // [THEN] Posted vendor documents (prepayment, invoice) have "Vendor Bank Acc. Code" = "B"
        // [THEN] Vendor ledger entries (prepayment, invoice) have "Recipient Bank Account" = "B"
        VerifyVendorRecipientBankAccAfterPrepmtAndSuggestPayments(
          GenJournalLine, VendorNo, PurchaseHeader."Vendor Bank Acc. Code", PurchaseHeader."Vendor Bank Acc. Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPrepmtWithoutPreferredBankAcc()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Customer Bank Account]
        // [SCENARIO 380970] Posted Sales Order with prepayment in case of blank Customer."Preferred Bank Account Code"
        Initialize();

        // [GIVEN] Customer with "Preferred Bank Account Code" = ""
        CustomerNo := LibrarySales.CreateCustomerNo();
        // [GIVEN] Sales Order with prepayment percent. SalesHeader."Cust. Bank Acc. Code" has default value "" from customer card.
        CreateSalesOrderWithPrepmtPct(SalesHeader, CustomerNo);

        // [WHEN] Post Prepayment Invoice. Post Order.
        PostSalesPrepaymentInvoiceAndOrder(SalesHeader);

        // [THEN] Posted customer documents (prepayment, invoice) have "Cust. Bank Acc. Code" = ""
        // [THEN] Customer ledger entries (prepayment, invoice) have "Recipient Bank Account" = ""
        VerifyCustomerRecipientBankAccAfterPrepmt(CustomerNo, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPrepmtWithPreferredBankAcc()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        CustomerPreferredBankAccountCode: Code[20];
    begin
        // [FEATURE] [Sales] [Customer Bank Account]
        // [SCENARIO 380970] Posted Sales Order with prepayment in case of Customer."Preferred Bank Account Code"
        Initialize();

        // [GIVEN] Customer with "Preferred Bank Account Code" = "A"
        CustomerNo := CreateCustomerWithPreferredBankAccount(CustomerPreferredBankAccountCode);
        // [GIVEN] Sales Order with prepayment percent. SalesHeader."Cust. Bank Acc. Code" has default value "A" from customer card.
        CreateSalesOrderWithPrepmtPct(SalesHeader, CustomerNo);

        // [WHEN] Post Prepayment Invoice. Post Order.
        PostSalesPrepaymentInvoiceAndOrder(SalesHeader);

        // [THEN] Posted customer documents (prepayment, invoice) have "Cust. Bank Acc. Code" = "A"
        // [THEN] Customer ledger entries (prepayment, invoice) have "Recipient Bank Account" = "A"
        VerifyCustomerRecipientBankAccAfterPrepmt(CustomerNo, CustomerPreferredBankAccountCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPrepmtWithoutPreferredBankAccAndModifyHeaderVendBankAcc()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Customer Bank Account]
        // [SCENARIO 380970] Posted Sales Order with prepayment in case of blank Customer."Preferred Bank Account Code" and SalesHeader."Cust. Bank Acc. Code"
        Initialize();

        // [GIVEN] Customer with "Preferred Bank Account Code" = ""
        CustomerNo := LibrarySales.CreateCustomerNo();
        // [GIVEN] Sales Order with prepayment percent. Change SalesHeader."Cust. Bank Acc. Code" = "B"
        CreateSalesOrderWithPrepmtPct(SalesHeader, CustomerNo);

        // [WHEN] Post Prepayment Invoice. Post Order.
        PostSalesPrepaymentInvoiceAndOrder(SalesHeader);

        // [THEN] Posted customer documents (prepayment, invoice) have "Cust. Bank Acc. Code" = "B"
        // [THEN] Customer ledger entries (prepayment, invoice) have "Recipient Bank Account" = "B"
        VerifyCustomerRecipientBankAccAfterPrepmt(CustomerNo, SalesHeader."Cust. Bank Acc. Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPrepmtWithPreferredBankAccAndBlankHeaderVendBankAcc()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        CustomerPreferredBankAccountCode: Code[20];
    begin
        // [FEATURE] [Sales] [Customer Bank Account]
        // [SCENARIO 380970] Posted Sales Order with prepayment in case of Customer."Preferred Bank Account Code" and blank SalesHeader."Cust. Bank Acc. Code"
        Initialize();

        // [GIVEN] Customer with "Preferred Bank Account Code" = "A"
        CustomerNo := CreateCustomerWithPreferredBankAccount(CustomerPreferredBankAccountCode);
        // [GIVEN] Sales Order with prepayment percent. Change SalesHeader."Cust. Bank Acc. Code" = ""
        CreateSalesOrderWithPrepmtPct(SalesHeader, CustomerNo);
        UpdateSalesHeaderCustomerBankAccCode(SalesHeader, '');

        // [WHEN] Post Prepayment Invoice. Post Order.
        PostSalesPrepaymentInvoiceAndOrder(SalesHeader);

        // [THEN] Posted customer documents (prepayment, invoice) have "Cust. Bank Acc. Code" = ""
        // [THEN] Customer ledger entries (prepayment, invoice) have "Recipient Bank Account" = ""
        VerifyCustomerRecipientBankAccAfterPrepmt(CustomerNo, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPrepmtWithPreferredBankAccAndModifyHeaderVendBankAcc()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        CustomerPreferredBankAccountCode: Code[20];
    begin
        // [FEATURE] [Sales] [Customer Bank Account]
        // [SCENARIO 380970] Posted Sales Order with prepayment in case of Customer."Preferred Bank Account Code" and changed SalesHeader."Cust. Bank Acc. Code"
        Initialize();

        // [GIVEN] Customer with "Preferred Bank Account Code" = "A"
        CustomerNo := CreateCustomerWithPreferredBankAccount(CustomerPreferredBankAccountCode);
        // [GIVEN] Sales Order with prepayment percent. Change SalesHeader."Cust. Bank Acc. Code" = "B"
        CreateSalesOrderWithPrepmtPct(SalesHeader, CustomerNo);
        UpdateSalesHeaderCustomerBankAccCode(SalesHeader, CreateCustomerBankAccountNo(CustomerNo));

        // [WHEN] Post Prepayment Invoice. Post Order.
        PostSalesPrepaymentInvoiceAndOrder(SalesHeader);

        // [THEN] Posted customer documents (prepayment, invoice) have "Cust. Bank Acc. Code" = "B"
        // [THEN] Customer ledger entries (prepayment, invoice) have "Recipient Bank Account" = "B"
        VerifyCustomerRecipientBankAccAfterPrepmt(CustomerNo, SalesHeader."Cust. Bank Acc. Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecipientBankAccountOnPaymentJnlLineIsMatchToAppliedSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        CustomerPreferredBankAccNo: Code[20];
        CustomerBankAccNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Customer Bank Account]
        // [SCENARIO 381322] "Recipient Bank Account" in Payment Journal Line should match to "Recipient Bank Account" in applied document
        Initialize();

        // [GIVEN] Customer with "Preferred Bank Account Code" = "A" and one more Customer Bank Account = "B"
        CustomerNo := CreateCustomerWithPreferredBankAccount(CustomerPreferredBankAccNo);
        CustomerBankAccNo := CreateCustomerBankAccountNo(CustomerNo);

        // [GIVEN] Posted Sales Order "Inv" with Customer Bank Account = "B"
        InvoiceNo := CreatePostSalesOrderWithBankAccount(SalesHeader, CustomerNo, CustomerBankAccNo);

        // [WHEN] Set posted document "Inv" as "Applies-to Doc. No." in payment Gen. Journal Line
        CreateGenJnlLineWithAppln(GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, InvoiceNo);

        // [THEN] "Recipient Bank Account" is equal to Customer Bank Account "B" in Payment Journal Line
        GenJournalLine.TestField("Recipient Bank Account", CustomerBankAccNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecipientBankAccountOnPaymentJnlLineIsMatchToPreferredBankAccountWhenClearAppliedSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        CustomerPreferredBankAccNo: Code[20];
        CustomerBankAccNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Customer Bank Account]
        // [SCENARIO 381322] "Recipient Bank Account" in Payment Journal Line should match to "Preferred Bank Account Code" when clear applied document
        Initialize();

        // [GIVEN] Customer with "Preferred Bank Account Code" = "A" and one more Customer Bank Account = "B"
        CustomerNo := CreateCustomerWithPreferredBankAccount(CustomerPreferredBankAccNo);
        CustomerBankAccNo := CreateCustomerBankAccountNo(CustomerNo);

        // [GIVEN] Posted Sales Order "Inv" with Customer Bank Account = "B"
        InvoiceNo := CreatePostSalesOrderWithBankAccount(SalesHeader, CustomerNo, CustomerBankAccNo);

        // [GIVEN] Payment Gen. Journal Line has posted document "Inv" as "Applies-to Doc. No."
        CreateGenJnlLineWithAppln(GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, InvoiceNo);

        // [WHEN] Clear "Applies-to Doc. Type"
        GenJournalLine.Validate("Applies-to Doc. Type", 0);

        // [THEN] "Recipient Bank Account" is equal to Preferred Bank Account "A" in Payment Journal Line
        GenJournalLine.TestField("Recipient Bank Account", CustomerPreferredBankAccNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecipientBankAccountOnPaymentJnlLineIsMatchToAppliedPurchInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        VendorPreferredBankAccNo: Code[20];
        VendorBankAccNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Vendor Bank Account]
        // [SCENARIO 381322] "Recipient Bank Account" in Payment Journal Line should match to "Recipient Bank Account" in applied sales document
        Initialize();

        // [GIVEN] Vendor with "Preferred Bank Account Code" = "A" and one more Vendor Bank Account = "B"
        VendorNo := CreateVendorWithPreferredBankAccount(VendorPreferredBankAccNo);
        VendorBankAccNo := CreateVendorBankAccountNo(VendorNo);

        // [GIVEN] Posted Purchase Order "Inv" with Vendor Bank Account = "B"
        InvoiceNo := CreatePostPurchOrderWithBankAccount(PurchaseHeader, VendorNo, VendorBankAccNo);

        // [WHEN] Set posted document "Inv" as "Applies-to Doc. No." in payment Gen. Journal Line
        CreateGenJnlLineWithAppln(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, InvoiceNo);

        // [THEN] "Recipient Bank Account" is equal to Vendor Bank Account "B" in Payment Journal Line
        GenJournalLine.TestField("Recipient Bank Account", VendorBankAccNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecipientBankAccountOnPaymentJnlLineIsMatchToPreferredBankAccountWhenClearAppliedPurchDoc()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        VendorPreferredBankAccNo: Code[20];
        VendorBankAccNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Vendor Bank Account]
        // [SCENARIO 381322] "Recipient Bank Account" in Payment Journal Line should match to "Preferred Bank Account Code" when clear applied purchase document
        Initialize();

        // [GIVEN] Vendor with "Preferred Bank Account Code" = "A" and one more Vendor Bank Account = "B"
        VendorNo := CreateVendorWithPreferredBankAccount(VendorPreferredBankAccNo);
        VendorBankAccNo := CreateVendorBankAccountNo(VendorNo);

        // [GIVEN] Posted Purchase Order "Inv" with Vendor Bank Account = "B"
        InvoiceNo := CreatePostPurchOrderWithBankAccount(PurchaseHeader, VendorNo, VendorBankAccNo);

        // [GIVEN] Payment Gen. Journal Line has posted document "Inv" as "Applies-to Doc. No."
        CreateGenJnlLineWithAppln(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, InvoiceNo);

        // [WHEN] Clear "Applies-to Doc. Type"
        GenJournalLine.Validate("Applies-to Doc. Type", 0);

        // [THEN] "Recipient Bank Account" is equal to Preferred Bank Account "A" in Payment Journal Line
        GenJournalLine.TestField("Recipient Bank Account", VendorPreferredBankAccNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VATBaseOfPurchaseOrderWithPmtDisc()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        VATEntry: Record "VAT Entry";
        InvNo: Code[20];
        PaymentDiscountBase: Decimal;
    begin
        // [FEATURE] [Purchase] [VAT] [Post Payment Discount]
        // [SCENARIO 204097] VAT Base does not include "Payment Discount" when post Purchase Order with "Post Payment Discount" option in "Purchases & Payables Setup"

        Initialize();

        // [GIVEN] "Post Payment Discount" is "Yes" in "Purchases & Payables Setup"
        PurchasesPayablesSetup.Get();
        UpdatePurchasesPayablesSetup(true, PurchasesPayablesSetup."Allow VAT Difference");  // Set "Post Payment Discount"

        // [GIVEN] Purchase Order with Amount = 100 and "Payment Discount %" = 5
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Order, CreateVendor(), LibraryRandom.RandDec(10, 2));

        // [GIVEN] "Payment Discount Type" is "Calc. Pmt. Disc. on Lines" in "General Ledger Setup" and calculate payment discount
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.",
          GeneralLedgerSetup."Unit-Amount Rounding Precision", GeneralLedgerSetup."Max. VAT Difference Allowed");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CalculateInvAndPmtDiscountsOnPurchaseOrder(PurchaseLine);

        // [WHEN] Post Purchase Order
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Two VAT Entries are created (one for payment discount, one for purchase order amount)
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", InvNo);
        Assert.RecordCount(VATEntry, 2);

        // [THEN] Total VAT Base of two entries is 95 (VAT Base of Purchase Order is 100. VAT Base of Payment Discount is -5. Total VAT Base is 100 - 5 = 95)
        VATEntry.CalcSums(Base);
        PaymentDiscountBase := Round(PurchaseLine.Amount * PurchaseHeader."Payment Discount %" / 100);
        VATEntry.TestField(Base, PurchaseLine.Amount - PaymentDiscountBase);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VATBaseOfSalesOrderWithPmtDisc()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        VATEntry: Record "VAT Entry";
        InvNo: Code[20];
        PaymentDiscountBase: Decimal;
    begin
        // [FEATURE] [Sales] [VAT] [Post Payment Discount]
        // [SCENARIO 204097] VAT Base does not include "Payment Discount" when post Sales Order with "Post Payment Discount" option in "Sales & Receivables Setup"

        Initialize();

        // [GIVEN] "Post Payment Discount" is "Yes" in "Sales & Receivables Setup"
        SalesReceivablesSetup.Get();
        UpdatePmtDiscInSalesReceivablesSetup(true);  // Set "Post Payment Discount"

        // [GIVEN] Sales Order with Amount = 100 and "Payment Discount %" = 5
        CreateSalesOrderWithPmtDisc(SalesHeader, SalesLine);

        // [GIVEN] "Payment Discount Type" is "Calc. Pmt. Disc. on Lines" in "General Ledger Setup" and calculate payment discount
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.",
          GeneralLedgerSetup."Unit-Amount Rounding Precision", GeneralLedgerSetup."Max. VAT Difference Allowed");
        CalculateInvAndPmtDiscountsOnSalesOrder(SalesHeader."No.");

        // [WHEN] Post Sales Order
        InvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Two VAT Entries are created (one for payment discount, one for sales order amount)
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", InvNo);
        Assert.RecordCount(VATEntry, 2);

        // [THEN] Total VAT Base of two entries is -95 (VAT Base of Sales Order is -100. VAT Base of Payment Discount is 5. Total VAT Base is 5 - 100 = -95)
        VATEntry.CalcSums(Base);
        PaymentDiscountBase := Round(SalesLine.Amount * SalesHeader."Payment Discount %" / 100);
        VATEntry.TestField(Base, PaymentDiscountBase - SalesLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TryCorrectClosedPostedPurchInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Correct Posted Invoice] [Invoice] [Purchase]
        // [SCENARIO 222227] An error when try Correct closed posted purchase invoice:
        // [SCENARIO 222227] "You cannot perform this action for closed or partially paid entries, nor for any entries that are created with the Cartera module."
        Initialize();

        // [GIVEN] Posted purchase invoice for vendor with payment method having "Create Bills" = TRUE
        PurchInvHeader.Get(
          CreatePostPurchOrderWithBankAccount(PurchaseHeader, CreateVendorWithPaymentMethod(CreatePaymentMethodWithCreateBills()), ''));

        // [WHEN] Perform "Correct" action for the posted invoice
        asserterror CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, false);

        // [THEN] An error has been thrown: "You cannot perform this action for closed or partially paid entries, nor for any entries that are created with the Cartera module."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(PostedInvoiceIsPaidCorrectOrCancelErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TryCancelClosedPostedPurchInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Cancelled Document] [Invoice] [Purchase]
        // [SCENARIO 222227] An error when try Cancel closed posted purchase invoice:
        // [SCENARIO 222227] "You cannot perform this action for closed or partially paid entries, nor for any entries that are created with the Cartera module."
        Initialize();

        // [GIVEN] Posted purchase invoice for vendor with payment method having "Create Bills" = TRUE
        PurchInvHeader.Get(
          CreatePostPurchOrderWithBankAccount(PurchaseHeader, CreateVendorWithPaymentMethod(CreatePaymentMethodWithCreateBills()), ''));

        // [WHEN] Perform "Cancel" action for the posted invoice
        asserterror CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);

        // [THEN] An error has been thrown: "You cannot perform this action for closed or partially paid entries, nor for any entries that are created with the Cartera module."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(PostedInvoiceIsPaidCorrectOrCancelErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TryCorrectClosedPostedSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Correct Posted Invoice] [Invoice] [Sales]
        // [SCENARIO 222227] An error when try Correct closed posted sales invoice:
        // [SCENARIO 222227] "You cannot perform this action for closed or partially paid entries, nor for any entries that are created with the Cartera module."
        Initialize();

        // [GIVEN] Posted sales invoice for customer with payment method having "Create Bills" = TRUE
        SalesInvoiceHeader.Get(
          CreatePostSalesOrderWithBankAccount(SalesHeader, CreateCustomerWithPaymentMethod(CreatePaymentMethodWithCreateBills()), ''));

        // [WHEN] Perform "Correct" action for the posted invoice
        asserterror CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, false);

        // [THEN] An error has been thrown: "You cannot perform this action for closed or partially paid entries, nor for any entries that are created with the Cartera module."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(PostedInvoiceIsPaidCorrectOrCancelErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TryCancelClosedPostedSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Cancelled Document] [Invoice] [Sales]
        // [SCENARIO 222227] An error when try Cancel closed posted sales invoice:
        // [SCENARIO 222227] "You cannot perform this action for closed or partially paid entries, nor for any entries that are created with the Cartera module."
        Initialize();

        // [GIVEN] Posted sales invoice for customer with payment method having "Create Bills" = TRUE
        SalesInvoiceHeader.Get(
          CreatePostSalesOrderWithBankAccount(SalesHeader, CreateCustomerWithPaymentMethod(CreatePaymentMethodWithCreateBills()), ''));

        // [WHEN] Perform "Cancel" action for the posted invoice
        asserterror CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);

        // [THEN] An error has been thrown: "You cannot perform this action for closed or partially paid entries, nor for any entries that are created with the Cartera module."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(PostedInvoiceIsPaidCorrectOrCancelErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedRevChrgPurchaseInvoiceHasAutoinvoiceVaueForEnabledArchive()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        AutoinvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Autoinvoice] [Reverse Charge] [Archive]
        // [SCENARIO 223004] Posted purchase invoice has filled "Autoinvoice No." value in case of Reverse Charge and "Archive Orders" = TRUE
        Initialize();

        // [GIVEN] Purchases & Payables Setup "Archive Orders" = TRUE
        LibraryPurchase.SetArchiveOrders(true);
        // [GIVEN] Purchase order with Reverse Charge VAT posting setup
        CreateReverseChargeVATPostingSetup(VATPostingSetup);
        CreatePurchaseOrderWithGivenVATSetup(PurchaseHeader, VATPostingSetup);
        AutoinvoiceNo := GetNextAutoDocNo();

        // [WHEN] Post the order
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [THEN] Posted purchase invoice has filled "Autoinvoice No." value
        PurchInvHeader.TestField("Autoinvoice No.", AutoinvoiceNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedRevChrgPurchaseInvoiceHasAutoinvoiceVaueForDisabledArchive()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        AutoinvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Autoinvoice] [Reverse Charge] [Archive]
        // [SCENARIO 223004] Posted purchase invoice has filled "Autoinvoice No." value in case of Reverse Charge and "Archive Orders" = FALSE
        Initialize();

        // [GIVEN] Purchases & Payables Setup "Archive Orders" = FALSE
        LibraryPurchase.SetArchiveOrders(false);
        // [GIVEN] Purchase order with Reverse Charge VAT posting setup
        CreateReverseChargeVATPostingSetup(VATPostingSetup);
        CreatePurchaseOrderWithGivenVATSetup(PurchaseHeader, VATPostingSetup);
        AutoinvoiceNo := GetNextAutoDocNo();

        // [WHEN] Post the order
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [THEN] Posted purchase invoice has filled "Autoinvoice No." value
        PurchInvHeader.TestField("Autoinvoice No.", AutoinvoiceNo);
    end;

    [Test]
    [HandlerFunctions('TrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TrialBalanceReportWithIncludeOpeningEntriesAndAccumulateBalance()
    var
        AccountingPeriod: Record "Accounting Period";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Report] [G/L Balance]
        // [SCENARIO 278929] Trial Balance report with Include Opening Entries and Accumulate Balance options only counts opening entries once
        Initialize();
        Amount := LibraryRandom.RandDec(1000, 2);

        // [GIVEN] An accounting period
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.FindLast();

        // [GIVEN] A G/L Account with type = posting
        GLAccountNo := CreateGLAccountWithAccountType(GLAccount."Account Type"::Posting, '');

        // [GIVEN] There was an entry with credit amount for this account before the accounting period
        CreateAndPostGeneralJournalLine(
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, -Amount, '', AccountingPeriod."Starting Date" - 1);

        // [WHEN] Trial Balance report is run with Include Opening Entries and Accumulate Balance at date for the accounting period
        EnqueueValuesForTrialBalanceRequestPageHandler(
          '', GLAccountNo, false, true, true, GLAccount."Account Type"::Posting, AccountingPeriod."Starting Date");

        REPORT.Run(REPORT::"Trial Balance");
        // Handled by TrialBalanceRequestPageHandler.

        // [THEN] Opening entry was counted only once by the report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalCreditAmtAtEnd', Amount);
        LibraryReportDataset.AssertElementWithValueExists(GLAccountNoCap, GLAccountNo);
    end;

    [Test]
    [HandlerFunctions('SimpleTrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TrialBalanceReportNegativeCreditAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Report] [Trial Balance]
        // [SCENARIO 428389] Trial Balance report prints negative credit amount
        Initialize();
        Amount := LibraryRandom.RandDec(1000, 2);

        // [GIVEN] A G/L Account with type = posting
        GLAccountNo := CreateGLAccountWithAccountType(GLAccount."Account Type"::Posting, '');

        // [GIVEN] Create and post gen. journal line with "Credit Amount" = -100
        CreateGeneralJournalLine(
            GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount, '', WorkDate());
        GenJournalLine.Validate("Credit Amount", -Amount);
        GenJournalLine.Modify();
        GenJournalTemplate.Get(GenJournalLine."Journal Template Name");
        GenJournalTemplate.Validate("Force Doc. Balance", true);
        GenJournalTemplate.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Trial Balance report is run with Include Opening Entries and Accumulate Balance at date for the accounting period
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(GLAccountNo);
        Report.Run(Report::"Trial Balance");
        // Handled by SimpleTrialBalanceRequestPageHandler.

        // [THEN] Credit amount -100 printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CreditAmount_GLAccount', -Amount);
        LibraryReportDataset.AssertElementWithValueExists('CreditAmount2_GLAccount', -Amount);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceBookOnlySIIRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnlySIIDocumentsShownInSalesInvBookWhenOnlySIIDocsOptionEnabled()
    var
        SalesHeader: Record "Sales Header";
        DummyVATEntry: Record "VAT Entry";
        PostedDocNo: array[2] of Code[20];
    begin
        // [FEATURE] [Report] [Sales] [Sales Invoice Book]
        // [SCENARIO 230147] Only documents with the "Do Not Send To SII" option disabled include to the Sales Invoice Book report that run with the "Only Include SII Documents" option enabled

        Initialize();

        // [GIVEN] Posted Sales Invoice "X" with the "Do Not Send To SII" option enabled
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.Validate("Do Not Send To SII", true);
        SalesHeader.Modify(true);
        PostedDocNo[1] := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [GIVEN] Posted Sales Invoice "Y" with the "Do Not Send To SII" option disabled
        LibrarySales.CreateSalesInvoice(SalesHeader);
        PostedDocNo[2] := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [WHEN] Run report "Sales Invoice Book"
        DummyVATEntry.SetFilter("Document No.", '%1|%2', PostedDocNo[1], PostedDocNo[2]);
        DummyVATEntry.SetRange("Document Type", DummyVATEntry."Document Type"::Invoice);
        REPORT.Run(REPORT::"Sales Invoice Book", true, false, DummyVATEntry);

        // [THEN] Only invoice "Y" present in the report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueNotExist('VATEntry_Document_No_', PostedDocNo[1]);
        LibraryReportDataset.AssertElementTagWithValueExists('VATEntry_Document_No_', PostedDocNo[2]);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AllDocumentsShownInSalesInvBookWhenSIIDocsOptionDisabled()
    var
        SalesHeader: Record "Sales Header";
        DummyVATEntry: Record "VAT Entry";
        PostedDocNo: array[2] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Report] [Sales] [Sales Invoice Book]
        // [SCENARIO 230147] All the documents include to the Sales Invoice Book report that run with the "Only Include SII Documents" option disabled

        Initialize();

        // [GIVEN] Posted sales invoices "X" and "Y" with the "Do Not Send To SII" option disabled
        for i := 1 to ArrayLen(PostedDocNo) do begin
            LibrarySales.CreateSalesInvoice(SalesHeader);
            PostedDocNo[i] := LibrarySales.PostSalesDocument(SalesHeader, false, false);
        end;

        // [WHEN] Run report "Sales Invoice Book"
        DummyVATEntry.SetFilter("Document No.", '%1|%2', PostedDocNo[1], PostedDocNo[2]);
        DummyVATEntry.SetRange("Document Type", DummyVATEntry."Document Type"::Invoice);
        REPORT.Run(REPORT::"Sales Invoice Book", true, false, DummyVATEntry);

        // [THEN] Both invoices "X" and "Y" present in the report
        LibraryReportDataset.LoadDataSetFile();
        for i := 1 to ArrayLen(PostedDocNo) do
            LibraryReportDataset.AssertElementTagWithValueExists('VATEntry_Document_No_', PostedDocNo[i]);
    end;

    [Test]
    [HandlerFunctions('PurchasesInvoiceBookOnlySIIRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnlySIIDocumentsShownInPurchInvBookWhenOnlySIIDocsOptionEnabled()
    var
        PurchaseHeader: Record "Purchase Header";
        DummyVATEntry: Record "VAT Entry";
        PostedDocNo: array[2] of Code[20];
    begin
        // [FEATURE] [Report] [Purchase] [Purchase Invoice Book]
        // [SCENARIO 230147] Only documents with the "Do Not Send To SII" option disabled include to the Sales Invoice Book report that run with the "Only Include SII Documents" option enabled

        Initialize();

        // [GIVEN] Posted Purchase Invoice "X" with the "Do Not Send To SII" option enabled
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Do Not Send To SII", true);
        PurchaseHeader.Modify(true);
        PostedDocNo[1] := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false);

        // [GIVEN] Posted Purchase Invoice "Y" with the "Do Not Send To SII" option disabled
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PostedDocNo[2] := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false);

        // [WHEN] Run report "Purchases Invoice Book"
        DummyVATEntry.SetFilter("Document No.", '%1|%2', PostedDocNo[1], PostedDocNo[2]);
        DummyVATEntry.SetRange("Document Type", DummyVATEntry."Document Type"::Invoice);
        REPORT.Run(REPORT::"Purchases Invoice Book", true, false, DummyVATEntry);

        // [THEN] Only invoice "Y" present in the report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueNotExist('VATEntry_Document_No_', PostedDocNo[1]);
        LibraryReportDataset.AssertElementTagWithValueExists('VATEntry_Document_No_', PostedDocNo[2]);
    end;

    [Test]
    [HandlerFunctions('PurchasesInvoiceBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AllDocumentsShownInPurchInvBookWhenSIIDocsOptionDisabled()
    var
        PurchaseHeader: Record "Purchase Header";
        DummyVATEntry: Record "VAT Entry";
        PostedDocNo: array[2] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Report] [Purchase] [Purchase Invoice Book]
        // [SCENARIO 230147] All the documents include to the Sales Invoice Book report that run with the "Only Include SII Documents" option disabled

        Initialize();

        // [GIVEN] Posted purchase invoices "X" and "Y" with the "Do Not Send To SII" option disabled
        for i := 1 to ArrayLen(PostedDocNo) do begin
            LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
            PostedDocNo[i] := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false);
        end;

        // [WHEN] Run report "Purchase Invoice Book"
        DummyVATEntry.SetFilter("Document No.", '%1|%2', PostedDocNo[1], PostedDocNo[2]);
        DummyVATEntry.SetRange("Document Type", DummyVATEntry."Document Type"::Invoice);
        REPORT.Run(REPORT::"Purchases Invoice Book", true, false, DummyVATEntry);

        // [THEN] Both invoices "X" and "Y" present in the report
        LibraryReportDataset.LoadDataSetFile();
        for i := 1 to ArrayLen(PostedDocNo) do
            LibraryReportDataset.AssertElementTagWithValueExists('VATEntry_Document_No_', PostedDocNo[i]);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        isInitialized := true;
        Commit();
    end;

    local procedure ApplyCustomerLedgerEntry(var CustomerLedgerEntries: TestPage "Customer Ledger Entries"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        CustomerLedgerEntries.OpenEdit();
        CustomerLedgerEntries.FILTER.SetFilter("Entry No.", Format(CustLedgerEntry."Entry No."));
        CustomerLedgerEntries."Apply Entries".Invoke();  // Invokes ApplyCustomerEntriesModalPageHandler.
    end;

    local procedure ApplyVendorLedgerEntry(var VendorLedgerEntries: TestPage "Vendor Ledger Entries"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, DocumentNo);
        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.FILTER.SetFilter("Entry No.", Format(VendorLedgerEntry."Entry No."));
        VendorLedgerEntries.ActionApplyEntries.Invoke();  // Invokes ApplyVendorEntriesModalPageHandler.
    end;

    local procedure CalculateInvAndPmtDiscountsOnPurchaseOrder(PurchaseLine: Record "Purchase Line")
    begin
        CODEUNIT.Run(CODEUNIT::"Purch.-Disc. (Yes/No)", PurchaseLine);
    end;

    local procedure CalculateInvAndPmtDiscountsOnSalesOrder(DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Sales-Disc. (Yes/No)", SalesLine);
    end;

    local procedure CalcPostedPurchInvPmtDiscAmt(PostedDocNo: Code[20]) Result: Decimal
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        with PurchInvLine do begin
            SetRange("Document No.", PostedDocNo);
            FindSet();
            repeat
                Result += "Pmt. Discount Amount";
            until Next() = 0;
        end;
    end;

    local procedure CalcPurchDocPmtDiscAmt(DocumentNo: Code[20]) Result: Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        with PurchaseLine do begin
            SetRange("Document No.", DocumentNo);
            FindSet();
            repeat
                Result += "Pmt. Discount Amount";
            until Next() = 0;
        end;
    end;

    local procedure CalcPostedSalesInvPmtDiscAmt(PostedDocNo: Code[20]) Result: Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        with SalesInvoiceLine do begin
            SetRange("Document No.", PostedDocNo);
            FindSet();
            repeat
                Result += "Pmt. Discount Amount";
            until Next() = 0;
        end;
    end;

    local procedure CalcSalesDocPmtDiscAmt(DocumentNo: Code[20]) Result: Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        with SalesLine do begin
            SetRange("Document No.", DocumentNo);
            FindSet();
            repeat
                Result += "Pmt. Discount Amount";
            until Next() = 0;
        end;
    end;

    local procedure CreateAndPostGeneralJournalLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; ShortcutDimensionOneCode: Code[20]; PostingDate: Date): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalLine(GenJournalLine, AccountType, AccountNo, Amount, ShortcutDimensionOneCode, PostingDate);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; ShortcutDimensionOneCode: Code[20]; PostingDate: Date): Code[20]
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        BankAccount.SetRange(Blocked, false);
        BankAccount.FindFirst();
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Shortcut Dimension 1 Code", ShortcutDimensionOneCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesLine."Document Type"::Order, CustomerNo);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem());
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // True for Ship and Invoice.
    end;

    local procedure CreateAndPostServiceDocument(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20]; No: Code[20]; VATRegistrationNoFormat: Text[20]; CorrectedInvoiceNo: Code[20]): Code[20]
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        ServiceHeader.Validate("VAT Registration No.", VATRegistrationNoFormat);
        ServiceHeader.Validate("Corrected Invoice No.", CorrectedInvoiceNo);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, No);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);  // True for Ship and Invoice and False for Consume.
        exit(ServiceHeader."Last Posting No.");
    end;

    local procedure CreateCustomerWithShipToAddress(var Customer: Record Customer; var ShipToAddress: Record "Ship-to Address")
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Modify(true);

        LibraryERM.CreateCountryRegion(CountryRegion);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        ShipToAddress.Validate("Country/Region Code", CountryRegion.Code);
        ShipToAddress.Modify(true);
    end;

    local procedure CreateCustomerSetupCountryRegion(var Customer: Record Customer)
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Modify(true);
    end;

    local procedure SetupCustomers(var Customer: Record Customer; var CustomerBillTo: Record Customer)
    begin
        CreateCustomerSetupCountryRegion(Customer);
        CreateCustomerSetupCountryRegion(CustomerBillTo);
        Customer.Validate("Bill-to Customer No.", CustomerBillTo."No.");
        Customer.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ShipToCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Ship-to Code", ShipToCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccountWithAccountType(AccountType: Enum "G/L Account Type"; Totaling: Text): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Account Type", AccountType);
        GLAccount.Validate(Totaling, Totaling);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        exit(Item."No.");
    end;

    local procedure CreatePaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", (Format(LibraryRandom.RandIntInRange(5, 10)) + 'M'));  // Using Random Value for Due Date Calculation.
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; PaymentDiscountPct: Decimal)
    var
        CompanyInformation: Record "Company Information";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        CompanyInformation.Get();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Payment Discount %", PaymentDiscountPct);
        PurchaseHeader.Validate("VAT Registration No.", CompanyInformation."VAT Registration No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Using Random Value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(50, 100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithPrepmtPct(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(10, 30));
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithPrepmtPct(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(10, 30));
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateAndAssignPurchaseLineWithItemCharge(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type"; DocNo: Code[20]; DocLineNo: Integer; ItemNo: Code[20])
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, DocType, DocNo, DocLineNo, ItemNo);
    end;

    local procedure CreateSalesOrderWithPmtDisc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesLine."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Payment Discount %", LibraryRandom.RandDec(10, 2));
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem());
    end;

    local procedure CreatePostSalesDocWithPmtDisc(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesLine."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Payment Discount %", LibraryRandom.RandDec(10, 2));
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem());
        CalculateInvAndPmtDiscountsOnSalesOrder(SalesHeader."No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Using Random value for quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(50, 100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        CompanyInformation: Record "Company Information";
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        Vendor: Record Vendor;
    begin
        CompanyInformation.Get();
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CompanyInformation."Country/Region Code");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        Vendor.Validate("Payment Method Code", FindPaymentMethod());
        Vendor.Validate("VAT Registration No.", CompanyInformation."VAT Registration No.");
        Vendor.Validate("Payment Terms Code", CreatePaymentTerms());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithPreferredBankAccount(var PreferredBankAccountCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        with Vendor do begin
            PreferredBankAccountCode := CreateVendorBankAccountNo("No.");
            Validate("Preferred Bank Account Code", PreferredBankAccountCode);
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure CreateCustomerWithPreferredBankAccount(var PreferredBankAccountCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        with Customer do begin
            PreferredBankAccountCode := CreateCustomerBankAccountNo("No.");
            Validate("Preferred Bank Account Code", PreferredBankAccountCode);
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure CreateVendorBankAccountNo(VendorNo: Code[20]): Code[20]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        exit(VendorBankAccount.Code);
    end;

    local procedure CreateCustomerBankAccountNo(CustomerNo: Code[20]): Code[20]
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CustomerNo);
        exit(CustomerBankAccount.Code);
    end;

    local procedure CreateGenJnlLineWithAppln(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AppliesToDocNo: Code[20])
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, AccountType, AccountNo, 0);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePostSalesOrderWithBankAccount(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; CustomerBankAccNo: Code[20]): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesLine."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Cust. Bank Acc. Code", CustomerBankAccNo);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem());
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostPurchOrderWithBankAccount(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; VendorBankAccNo: Code[20]): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseLine."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Vendor Bank Acc. Code", VendorBankAccNo);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateCustomerWithPaymentMethod(PaymentMethodCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        with Customer do begin
            Validate("Payment Method Code", PaymentMethodCode);
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure CreateVendorWithPaymentMethod(PaymentMethodCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        with Vendor do begin
            Validate("Payment Method Code", PaymentMethodCode);
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure CreatePaymentMethodWithCreateBills(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        with PaymentMethod do begin
            Validate("Create Bills", true);
            Modify(true);
            exit(Code);
        end;
    end;

    local procedure CreateReverseChargeVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        with VATPostingSetup do begin
            LibraryERM.CreateVATPostingSetupWithAccounts(
              VATPostingSetup, "VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(10, 30));
            Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
            Modify(true);
        end;
    end;

    local procedure CreatePurchaseOrderWithGivenVATSetup(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure PostPurchasePrepaymentInvoiceAndOrder(PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure PostSalesPrepaymentInvoiceAndOrder(SalesHeader: Record "Sales Header")
    begin
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure EnqueueValuesForTrialBalanceRequestPageHandler(DepartmentFilter: Code[20]; GLAccountFilter: Text[50]; IncludeClosingEntries: Boolean; IncludeOpeningEntries: Boolean; AccumulateBalance: Boolean; AccountType: Enum "G/L Account Type"; StartingDate: Date)
    begin
        // Enqueue for TrialBalanceRequestPageHandler.
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(AccountType);
        LibraryVariableStorage.Enqueue(GLAccountFilter);
        LibraryVariableStorage.Enqueue(IncludeClosingEntries);
        LibraryVariableStorage.Enqueue(IncludeOpeningEntries);
        LibraryVariableStorage.Enqueue(AccumulateBalance);
        LibraryVariableStorage.Enqueue(DepartmentFilter);
    end;

    local procedure FindAndUpdateGLAccountWithAccountTypeAsHeading(Totaling: Text): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        // Finding GLAccount of length 3 with Account Type heading to run the report - 10716 Official Acc.Summarized Book, otherwise skips the report.
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Heading);
        GLAccount.FindSet();
        repeat
            GLAccount.Next();
        until StrLen(GLAccount."No.") = 3;
        GLAccount.Validate(Totaling, Totaling);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure FindPaymentMethod(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.SetRange("Create Bills", true);
        LibraryERM.FindPaymentMethod(PaymentMethod);
        exit(PaymentMethod.Code);
    end;

    local procedure FindSalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; ItemNo: Code[20])
    begin
        with SalesShipmentLine do begin
            SetRange(Type, Type::Item);
            SetRange("No.", ItemNo);
            FindFirst();
        end;
    end;

    local procedure FindServiceInvoiceHeader(CustomerNo: Code[20]): Code[20]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);
        ServiceInvoiceHeader.FindFirst();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure GetDimensionValueCode(): Code[20]
    var
        DimensionValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        DimensionValue.SetRange("Dimension Code", GeneralLedgerSetup."Global Dimension 1 Code");
        DimensionValue.FindFirst();
        exit(DimensionValue.Code);
    end;

    local procedure GetNextAutoDocNo(): Code[20]
    var
        GLSetup: Record "General Ledger Setup";
        NoSeries: Codeunit "No. Series";
    begin
        GLSetup.Get();
        GLSetup.TestField("Autoinvoice Nos.");
        exit(NoSeries.PeekNextNo(GLSetup."Autoinvoice Nos."));
    end;

    local procedure OpenVATAmountOnSalesStatistics(No: Code[20])
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", No);
        SalesInvoice.Statistics.Invoke();
        SalesInvoice.Close();
    end;

    local procedure ReverseEntry()
    var
        ReversalEntry: Record "Reversal Entry";
        GLRegister: Record "G/L Register";
    begin
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");
    end;

    local procedure UpdateGeneralLedgerSetup(PaymentDiscountType: Option; DiscountCalculation: Option; UnitAmountRoundingPrecision: Decimal; MaxVATDifferenceAllowed: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Payment Discount Type", PaymentDiscountType);
        GeneralLedgerSetup.Validate("Discount Calculation", DiscountCalculation);
        GeneralLedgerSetup.Validate("Unit-Amount Rounding Precision", UnitAmountRoundingPrecision);
        GeneralLedgerSetup.Validate("Max. VAT Difference Allowed", MaxVATDifferenceAllowed);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePurchasesPayablesSetup(PostPaymentDiscount: Boolean; AllowVATDifference: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Post Payment Discount", PostPaymentDiscount);
        PurchasesPayablesSetup.Validate("Allow VAT Difference", AllowVATDifference);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetup(AllowVATDifference: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Allow VAT Difference", AllowVATDifference);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdatePmtDiscInSalesReceivablesSetup(PostPaymentDiscount: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Post Payment Discount", PostPaymentDiscount);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdatePurchaseHeaderVendorBankAccCode(var PurchaseHeader: Record "Purchase Header"; VendorBankAccCode: Code[20])
    begin
        PurchaseHeader.Validate("Vendor Bank Acc. Code", VendorBankAccCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateSalesHeaderCustomerBankAccCode(var SalesHeader: Record "Sales Header"; CustomerBankAccCode: Code[20])
    begin
        SalesHeader.Validate("Cust. Bank Acc. Code", CustomerBankAccCode);
        SalesHeader.Modify(true);
    end;

    local procedure RunSuggestVendorPayments(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalTemplate.Type::Payments);
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        Vendor.SetRange("No.", VendorNo);

        Clear(SuggestVendorPayments);
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        SuggestVendorPayments.InitializeRequest(
            WorkDate(), false, 0, false, WorkDate(), 'TEST_000', false, "Gen. Journal Account Type"::"G/L Account", '',
            "Bank Payment Type"::" ");
        SuggestVendorPayments.SetTableView(Vendor);
        SuggestVendorPayments.UseRequestPage(false);
        SuggestVendorPayments.RunModal();
    end;

    local procedure RunReportWithVATEntry(ReportID: Integer; DocNo: Code[20]; DocType: Enum "Gen. Journal Document Type")
    var
        DummyVATEntry: Record "VAT Entry";
    begin
        DummyVATEntry.SetRange("Document No.", DocNo);
        DummyVATEntry.SetRange("Document Type", DocType);
        Assert.RecordCount(DummyVATEntry, 1);
        REPORT.Run(ReportID, true, false, DummyVATEntry);
    end;

    local procedure VerifyReversedCustomerLedgEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        CustLedgerEntry.FindFirst();
        Assert.AreEqual(true, CustLedgerEntry.Reversed, ReverseSignMsg);
        VerifyCustLedgEntryStats(CustLedgerEntry, Amount);
        CustLedgerEntry.Get(CustLedgerEntry."Reversed by Entry No.");
        VerifyCustLedgEntryStats(CustLedgerEntry, -Amount);
    end;

    local procedure VerifyReversedVendorLedgEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, DocumentNo);
        VendorLedgerEntry.FindFirst();
        Assert.AreEqual(true, VendorLedgerEntry.Reversed, ReverseSignMsg);
        VerifyVendLedgEntryStats(VendorLedgerEntry, Amount);
        VendorLedgerEntry.Get(VendorLedgerEntry."Reversed by Entry No.");
        VerifyVendLedgEntryStats(VendorLedgerEntry, -Amount);
    end;

    local procedure VerifyCustLedgEntryStats(CustLedgerEntry: Record "Cust. Ledger Entry"; Amount: Decimal)
    begin
        Assert.AreNearlyEqual(Amount, CustLedgerEntry."Amount (LCY) stats.", LibraryERM.GetAmountRoundingPrecision(), ExpectedValueMsg);
        Assert.AreNearlyEqual(
          Amount, CustLedgerEntry."Remaining Amount (LCY) stats.", LibraryERM.GetAmountRoundingPrecision(), ExpectedValueMsg);
    end;

    local procedure VerifyVendLedgEntryStats(VendorLedgerEntry: Record "Vendor Ledger Entry"; Amount: Decimal)
    begin
        Assert.AreNearlyEqual(Amount, VendorLedgerEntry."Amount (LCY) stats.", LibraryERM.GetAmountRoundingPrecision(), ExpectedValueMsg);
        Assert.AreNearlyEqual(
          Amount, VendorLedgerEntry."Remaining Amount (LCY) stats.", LibraryERM.GetAmountRoundingPrecision(), ExpectedValueMsg);
    end;

    local procedure VerifyVendorLedgerEntry(VendorNo: Code[20]; PaymentDiscountAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount, "Remaining Amount");
        Assert.AreNearlyEqual(PaymentDiscountAmount, VendorLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), ExpectedValueMsg);
        Assert.AreNearlyEqual(
          PaymentDiscountAmount, VendorLedgerEntry."Remaining Amount", LibraryERM.GetAmountRoundingPrecision(), ExpectedValueMsg);
    end;

    local procedure VerifyPurchaseLine(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; LineAmount: Decimal; OutstandingAmountLCY: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
        Assert.AreNearlyEqual(
          LineAmount, PurchaseLine."VAT Base Amount", LibraryERM.GetAmountRoundingPrecision(), ExpectedValueMsg);
        Assert.AreNearlyEqual(
          OutstandingAmountLCY, PurchaseLine."Amount Including VAT", LibraryERM.GetAmountRoundingPrecision(), ExpectedValueMsg);
    end;

    local procedure VerifyCountryRegionCode(SalesHeader: Record "Sales Header"; Customer: Record Customer; CustomerBillTo: Record Customer; ExpectedShipToCountryRegionCode: Code[10]; ExpectedVATCountryRegionCode: Code[10])
    begin
        with SalesHeader do begin
            Assert.AreEqual(
              Customer."No.",
              "Sell-to Customer No.",
              StrSubstNo(FieldValueErr, FieldCaption("Sell-to Customer No.")));
            Assert.AreEqual(
              CustomerBillTo."No.",
              "Bill-to Customer No.",
              StrSubstNo(FieldValueErr, FieldCaption("Bill-to Customer No.")));
            Assert.AreEqual(
              Customer."Country/Region Code",
              "Sell-to Country/Region Code",
              StrSubstNo(FieldValueErr, FieldCaption("Sell-to Country/Region Code")));
            Assert.AreEqual(
              ExpectedShipToCountryRegionCode,
              "Ship-to Country/Region Code",
              StrSubstNo(FieldValueErr, FieldCaption("Ship-to Country/Region Code")));
            Assert.AreEqual(
              CustomerBillTo."Country/Region Code",
              "Bill-to Country/Region Code",
              StrSubstNo(FieldValueErr, FieldCaption("Bill-to Country/Region Code")));
            Assert.AreEqual(
              ExpectedVATCountryRegionCode,
              "VAT Country/Region Code",
              StrSubstNo(FieldValueErr, FieldCaption("VAT Country/Region Code")));
        end;
    end;

    local procedure VerifyCustGLUnapplication(CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        SourceCodeSetup.Get();
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        VerifyUnappliedGLEntries(DocumentNo, SourceCodeSetup."Unapplied Sales Entry Appln.", CustomerPostingGroup."Receivables Account");
    end;

    local procedure VerifyVendGLUnapplication(VendorNo: Code[20]; DocumentNo: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        SourceCodeSetup.Get();
        Vendor.Get(VendorNo);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        VerifyUnappliedGLEntries(DocumentNo, SourceCodeSetup."Unapplied Purch. Entry Appln.", VendorPostingGroup."Payables Account");
    end;

    local procedure VerifyUnappliedGLEntries(DocumentNo: Code[20]; SourceCode: Code[10]; GLAccNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        GLAmount: Decimal;
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Source Code", SourceCode);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        Assert.AreEqual(2, GLEntry.Count, IncorrectCountErr);
        GLEntry.FindSet();
        GLEntry.TestField(Amount);
        GLAmount := GLEntry.Amount;
        GLEntry.Next();
        GLEntry.TestField(Amount, -GLAmount);
    end;

    local procedure VerifyVendorRecipientBankAccAfterPrepmtAndSuggestPayments(GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; ExpectedPmtBankAcc: Code[20]; ExpectedDocBankAcc: Code[20])
    var
        DummyPurchInvHeader: Record "Purch. Inv. Header";
        DummyVendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        with GenJournalLine do begin
            SetRange("Journal Template Name", "Journal Template Name");
            SetRange("Journal Batch Name", "Journal Batch Name");
            SetRange("Recipient Bank Account", ExpectedPmtBankAcc);
        end;
        Assert.RecordCount(GenJournalLine, 2); // prepayment and invoice

        with DummyPurchInvHeader do begin
            SetRange("Buy-from Vendor No.", VendorNo);
            SetRange("Vendor Bank Acc. Code", ExpectedDocBankAcc);
        end;
        Assert.RecordCount(DummyPurchInvHeader, 2); // prepayment and invoice

        with DummyVendorLedgerEntry do begin
            SetRange("Vendor No.", VendorNo);
            SetRange("Recipient Bank Account", ExpectedDocBankAcc);
        end;
        Assert.RecordCount(DummyVendorLedgerEntry, 2); // prepayment and invoice
    end;

    local procedure VerifyCustomerRecipientBankAccAfterPrepmt(CustomerNo: Code[20]; ExpectedBankAcc: Code[20])
    var
        DummySalesInvoiceHeader: Record "Sales Invoice Header";
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        with DummySalesInvoiceHeader do begin
            SetRange("Sell-to Customer No.", CustomerNo);
            SetRange("Cust. Bank Acc. Code", ExpectedBankAcc);
        end;
        Assert.RecordCount(DummySalesInvoiceHeader, 2); // prepayment and invoice

        with DummyCustLedgerEntry do begin
            SetRange("Customer No.", CustomerNo);
            SetRange("Recipient Bank Account", ExpectedBankAcc);
        end;
        Assert.RecordCount(DummyCustLedgerEntry, 2); // prepayment and invoice
    end;

    local procedure VerifyCostOnItemLedgerEntry(ItemNo: Code[20]; CostAmtActual: Decimal; CostAmtNonInvtbl: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        with ItemLedgerEntry do begin
            SetRange("Item No.", ItemNo);
            FindFirst();
            CalcFields("Cost Amount (Actual)", "Cost Amount (Non-Invtbl.)");
            Assert.AreNearlyEqual(
              CostAmtActual, "Cost Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(), ExpectedValueMsg);
            Assert.AreNearlyEqual(
              CostAmtNonInvtbl, "Cost Amount (Non-Invtbl.)", LibraryERM.GetAmountRoundingPrecision(), ExpectedValueMsg);
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AgedAccountsReceivableRequestPageHandler(var AgedAccountsReceivable: TestRequestPage "Aged Accounts Receivable")
    var
        AgingBy: Option "Due Date","Posting Date","Document Date";
        HeadingType: Option "Date Interval","Number of Days";
    begin
        AgedAccountsReceivable.AgedAsOf.SetValue(WorkDate());
        AgedAccountsReceivable.Agingby.SetValue(AgingBy::"Due Date");
        AgedAccountsReceivable.PeriodLength.SetValue(PeriodLengthTxt);
        AgedAccountsReceivable.HeadingType.SetValue(HeadingType::"Date Interval");
        AgedAccountsReceivable.PrintDetails.SetValue(true);
        AgedAccountsReceivable.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AssemblyBOMRawMaterialsRequestPageHandler(var AssemblyBOMRawMaterials: TestRequestPage "Assembly BOM - Raw Materials")
    var
        BaseUnitOfMeasure: Variant;
    begin
        LibraryVariableStorage.Dequeue(BaseUnitOfMeasure);
        AssemblyBOMRawMaterials.Item.SetFilter("Base Unit of Measure", BaseUnitOfMeasure);
        AssemblyBOMRawMaterials.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OfficialAccSummarizedBookRequestPageHandler(var OfficialAccSummarizedBook: TestRequestPage "Official Acc.Summarized Book")
    var
        AccountType: Variant;
        FromDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(FromDate);
        LibraryVariableStorage.Dequeue(AccountType);
        OfficialAccSummarizedBook.FromDate.SetValue(FromDate);
        OfficialAccSummarizedBook.ToDate.SetValue(FromDate);
        OfficialAccSummarizedBook.AccountType.SetValue(AccountType);
        OfficialAccSummarizedBook.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceBookRequestPageHandler(var SalesInvoiceBook: TestRequestPage "Sales Invoice Book")
    begin
        SalesInvoiceBook.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceBookOnlySIIRequestPageHandler(var SalesInvoiceBook: TestRequestPage "Sales Invoice Book")
    begin
        SalesInvoiceBook.OnlyIncludeSIIDocumentsOption.SetValue(true);
        SalesInvoiceBook.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchasesInvoiceBookRequestPageHandler(var PurchasesInvoiceBook: TestRequestPage "Purchases Invoice Book")
    begin
        PurchasesInvoiceBook.SortPostDate.SetValue(true);
        PurchasesInvoiceBook.ShowAutoInvCred.SetValue(true);
        PurchasesInvoiceBook.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchasesInvoiceBookOnlySIIRequestPageHandler(var PurchasesInvoiceBook: TestRequestPage "Purchases Invoice Book")
    begin
        PurchasesInvoiceBook.SortPostDate.SetValue(true);
        PurchasesInvoiceBook.ShowAutoInvCred.SetValue(true);
        PurchasesInvoiceBook.OnlyIncludeSIIDocumentsOption.SetValue(true);
        PurchasesInvoiceBook.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries."Post Application".Invoke();  // Invokes PostApplicationModalPageHandler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.ActionPostApplication.Invoke();  // Invokes PostApplicationModalPageHandler.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TrialBalanceRequestPageHandler(var TrialBalance: TestRequestPage "Trial Balance")
    var
        AccountType: Variant;
        DateFilter: Variant;
        GlobalDimensionOneFilter: Variant;
        No: Variant;
        IncludeClosingEntries: Boolean;
        IncludeOpeningEntries: Boolean;
        AccumulateBalance: Boolean;
    begin
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(AccountType);
        LibraryVariableStorage.Dequeue(No);
        IncludeClosingEntries := LibraryVariableStorage.DequeueBoolean();
        IncludeOpeningEntries := LibraryVariableStorage.DequeueBoolean();
        AccumulateBalance := LibraryVariableStorage.DequeueBoolean();
        LibraryVariableStorage.Dequeue(GlobalDimensionOneFilter);
        TrialBalance.OnlyGLAccountsWithBalanceAtDate.SetValue(true);
        TrialBalance.IncludeClosingEntries.SetValue(IncludeClosingEntries);
        TrialBalance.IncludeOpeningEntries.SetValue(IncludeOpeningEntries);
        TrialBalance.AcumBalanceAtDate.SetValue(AccumulateBalance);
        TrialBalance."G/L Account".SetFilter("Account Type", Format(AccountType));
        TrialBalance."G/L Account".SetFilter("No.", No);
        TrialBalance."G/L Account".SetFilter("Date Filter", Format(ClosingDate(DateFilter)));
        TrialBalance."G/L Account".SetFilter("Global Dimension 1 Filter", GlobalDimensionOneFilter);
        TrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SimpleTrialBalanceRequestPageHandler(var TrialBalance: TestRequestPage "Trial Balance")
    begin
        TrialBalance.OnlyGLAccountsWithBalanceAtDate.SetValue(true);
        TrialBalance."G/L Account".SetFilter("Date Filter", Format(LibraryVariableStorage.DequeueText()));
        TrialBalance."G/L Account".SetFilter("No.", LibraryVariableStorage.DequeueText());
        TrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationModalPageHandler(var PostApplication: TestPage "Post Application")
    begin
        PostApplication.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceStatisticsPageHandler(var SalesInvoiceStatistics: TestPage "Sales Invoice Statistics")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        SalesInvoiceStatistics.Subform."VAT Amount".AssertEquals(VATAmount);
        SalesInvoiceStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        SalesStatistics.SubForm."VAT Amount".SetValue(VATAmount);
        SalesStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyCustomerEntriesModalPageHandler(var UnapplyCustomerEntries: TestPage "Unapply Customer Entries")
    begin
        UnapplyCustomerEntries.Unapply.Invoke();  // Invokes ConfirmHandler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyVendorEntriesModalPageHandler(var UnapplyVendorEntries: TestPage "Unapply Vendor Entries")
    begin
        UnapplyVendorEntries.Unapply.Invoke();  // Invokes ConfirmHandler.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text)
    begin
    end;
}

