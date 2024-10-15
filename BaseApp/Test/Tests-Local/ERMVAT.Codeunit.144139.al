codeunit 144139 "ERM VAT"
{
    // // [FEATURE] [VAT]
    // 
    //  1. Test to verify error on Unapply Vendor Invoice after running Calculate and Post VAT Settlement report with Unrealized VAT True.
    //  2. Test to verify error on Unapply Vendor Credit Memo after running Calculate and Post VAT Settlement report with Unrealized VAT False.
    //  3. Test to verify error on Unapply Customer Invoice after running Calculate and Post VAT Settlement report with Unrealized VAT True.
    //  4. Test to verify error on Unapply Customer Credit Memo after running Calculate and Post VAT Settlement report with Unrealized VAT False.
    //  5. Test to verify Unrealized VAT entry after posting Sales Credit Memo applied to Sales Invoice with Unrealized VAT.
    //  6. Test to verify Unrealized VAT entry after posting Purchase Credit Memo applied to Purchase Invoice with Unrealized VAT.
    //  7. Test to verify Service Tariff No. gets updated on Posted Sales Invoice when VAT Product Posting group is changed on the Sales Invoice Line.
    //  8. Test to verify Service Tariff No. gets updated on Posted Service Invoice when VAT Product Posting group is changed on the Service Invoice Line.
    //  9. Test to verify Service Tariff No. gets updated on Posted Purchase Invoice when VAT Product Posting group is changed on the Purchase Invoice Line.
    // 10. Test to verify Amount Including VAT field Caption on VAT Specification Subform.
    // 
    // Covers Test Cases for WI - 346274
    // ----------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                               TFS ID
    // ----------------------------------------------------------------------------------------------------------
    // UnapplyVendInvoiceErrorWithUnrealizedVAT                                                         156497
    // UnapplyCustInvoiceErrorWithUnrealizedVAT                                                         156499
    // ApplySalesInvoiceToCreditMemoWithUnrealizedVAT                                                   302461
    // ApplyPurchaseInvoiceToCreditMemoWithUnrealizedVAT                                                306986
    // ServiceTariffNoOnSalesInvoice                                                                    242868
    // ServiceTariffNoOnServiceInvoice                                                                  242870
    // ServiceTariffNoOnPurchaseInvoice                                                                 242869
    // AmountIncludingVATCaptionOnVATSpecificationSubform                                               273741
    // 
    // Covers Test Cases for WI - 346781
    // ----------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                               TFS ID
    // ----------------------------------------------------------------------------------------------------------
    // PurchNonDeductibleReverseVAT                                                                     355658

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryCashFlowHelper: Codeunit "Library - Cash Flow Helper";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUTUtility: Codeunit "Library UT Utility";
        AmountIncludingVATCap: Label 'Amount Including VAT';
        CannotUnapplyErr: Label 'You cannot unapply %1 No. %2 because the VAT settlement has been calculated and posted.';
        CaptionMsg: Label 'Caption must be same.';
        EntryDoesNotExistErr: Label '%1 with filters %2 does not exist.';
        WrongValueErr: Label 'Wrong value of field %2 in table %1.';
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler,UnapplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyVendInvoiceErrorWithUnrealizedVAT()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Quantity: Decimal;
        DirectUnitCost: Decimal;
    begin
        // Test to verify error on Unapply Vendor Invoice after running Calculate and Post VAT Settlement report with Unrealized VAT True.
        Initialize;
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random value for Quantity
        DirectUnitCost := LibraryRandom.RandDec(10, 2);  // Use Random value for Direct Unit Cost
        UnapplyVendorLedgerEntryError(
          true, VATPostingSetup."Unrealized VAT Type"::Percentage, PurchaseLine."Document Type"::Invoice, Quantity, DirectUnitCost,
          Quantity * DirectUnitCost / 2);  // True for Unrealized VAT and partial value required for Amount
    end;

    local procedure UnapplyVendorLedgerEntryError(UnrealizedVAT: Boolean; UnrealizedVATType: Option; DocumentType: Option; Quantity: Decimal; DirectUnitCost: Decimal; Amount: Decimal)
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
        AppliesToDocNo: Code[20];
    begin
        // Setup: Post Purchase Document and Payment Journal. Run Calculate and Post VAT Settlement report. Update VAT Period closed on Periodic Settlement VAT entry.
        GeneralLedgerSetup.Get;
        UpdateGeneralLedgerSetup(UnrealizedVAT, CalcDate('<CY - 1Y>', WorkDate));  // Required for test case to set last date of the previous year to Work Date.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", false, UnrealizedVATType);  // False for EU Service.
        AppliesToDocNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine, DocumentType, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"), '',
            CreateItem(VATPostingSetup."VAT Prod. Posting Group"), Quantity, DirectUnitCost); // Use Blank value for Applies To Doc No
        CreateAndPostGeneralJournalLine(
          GenJournalTemplate.Type::Payments, GenJournalLine."Account Type"::Vendor, PurchaseLine."Buy-from Vendor No.",
          Amount, CreateGLAccount(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase), DocumentType, AppliesToDocNo);
        RunCalcAndPostVATSettlementReport;
        UpdatePeriodicSettlementVATEntry;
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, PurchaseLine."Document Type", AppliesToDocNo);

        // Exercise: Unapply Vendor Ledger Entry.
        asserterror VendEntryApplyPostedEntries.UnApplyVendLedgEntry(VendorLedgerEntry."Entry No.");

        // Verify: Error on unapply Vendor Ledger Entry.
        Assert.ExpectedError(StrSubstNo(CannotUnapplyErr, PurchaseLine."Document Type", AppliesToDocNo));

        // Tear Down: Update VAT Posting Setup, General Ledger Setup and delete Periodic VAT Settlement entries.
        UpdateGeneralLedgerAndVATPostingSetups(GeneralLedgerSetup, VATPostingSetup);
        DeletePeriodicSettlementVATEntry(WorkDate);
        DeletePeriodicSettlementVATEntry(CalcDate('<1M>', WorkDate));  // '1M' required for one month next to Workdate
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler,UnapplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyCustInvoiceErrorWithUnrealizedVAT()
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // Test to verify error on Unapply Customer Invoice after running Calculate and Post VAT Settlement report with Unrealized VAT True.
        Initialize;
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random value for Quantity
        UnitPrice := LibraryRandom.RandDec(10, 2);  // Use Random value for Unit Price
        UnapplyCustomerLedgerEntryError(
          true, VATPostingSetup."Unrealized VAT Type"::Percentage, SalesLine."Document Type"::Invoice, Quantity, UnitPrice,
          -Quantity * UnitPrice / 2);  // True for Unrealized VAT and partial value required for Amount
    end;

    local procedure UnapplyCustomerLedgerEntryError(UnrealizedVAT: Boolean; UnrealizedVATType: Option; DocumentType: Option; Quantity: Decimal; UnitPrice: Decimal; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        AppliesToDocNo: Code[20];
    begin
        // Setup: Post Sales Document and Cash Receipt Journal. Run Calculate and Post VAT Settlement report. Update VAT Period closed on Periodic Settlement VAT entry.
        GeneralLedgerSetup.Get;
        UpdateGeneralLedgerSetup(UnrealizedVAT, CalcDate('<CY - 1Y>', WorkDate));  // Required for test case to set last date of the previous year to Work Date.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", false, UnrealizedVATType);  // False for EU Service
        AppliesToDocNo :=
          CreateAndPostSalesDocument(
            SalesLine, DocumentType, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"), '',
            CreateItem(VATPostingSetup."VAT Prod. Posting Group"), Quantity, UnitPrice);  // Use Blank value for Applies To Doc No.
        CreateAndPostGeneralJournalLine(
          GenJournalTemplate.Type::"Cash Receipts", GenJournalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.",
          Amount, CreateGLAccount(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale), DocumentType, AppliesToDocNo);
        RunCalcAndPostVATSettlementReport;
        UpdatePeriodicSettlementVATEntry;
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, SalesLine."Document Type", AppliesToDocNo);

        // Exercise: Unapply Customer Ledger Entry.
        asserterror CustEntryApplyPostedEntries.UnApplyCustLedgEntry(CustLedgerEntry."Entry No.");

        // Verify: Error on unapply Customer Ledger Entry.
        Assert.ExpectedError(StrSubstNo(CannotUnapplyErr, SalesLine."Document Type", AppliesToDocNo));

        // Tear Down: Update VAT Posting Setup, General Ledger Setup and delete Periodic VAT Settlement entries.
        UpdateGeneralLedgerAndVATPostingSetups(GeneralLedgerSetup, VATPostingSetup);
        DeletePeriodicSettlementVATEntry(WorkDate);
        DeletePeriodicSettlementVATEntry(CalcDate('<1M>', WorkDate));  // '1M' required for one month next to Workdate
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplySalesInvoiceToCreditMemoWithUnrealizedVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        AppliesToDocNo: Code[20];
        DocumentNo: Code[20];
    begin
        // Test to verify Unrealized VAT entry after posting Sales Credit Memo applied to Sales Invoice with Unrealized VAT.

        // Setup: Update General Ledger Setup and VAT Posting Setup. Create and Post Sales Invoice.
        Initialize;
        GeneralLedgerSetup.Get;
        UpdateGeneralLedgerSetup(true, CalcDate('<CY - 1Y>', WorkDate));  // Required for test case to set last date of the previous year to Work Date. True for Unrealized VAT.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."VAT Prod. Posting Group", false, VATPostingSetup."Unrealized VAT Type"::Percentage);  // False for EU Service
        AppliesToDocNo :=
          CreateAndPostSalesDocument(
            SalesLine, SalesLine."Document Type"::Invoice, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"), '',
            CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(10, 2),
            LibraryRandom.RandDec(100, 2));  // Use Random value for Quantity and Unit Price, Blank value for Applies To Doc No

        // Exercise: Create and Post Sales Credit Memo after applying posted Sales Invoice.
        DocumentNo :=
          CreateAndPostSalesDocument(
            SalesLine2, SalesLine2."Document Type"::"Credit Memo", SalesLine."Sell-to Customer No.", AppliesToDocNo, SalesLine."No.",
            SalesLine.Quantity, SalesLine."Unit Price");

        // Verify: General Ledger entries.
        VATPostingSetup2.Get(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VerifyGLEntries(
          DocumentNo, VATPostingSetup2."Sales VAT Unreal. Account", VATPostingSetup2."Sales VAT Account",
          Round(SalesLine.Amount * SalesLine."VAT %" / 100));

        // Tear Down: Update VAT Posting Setup and General Ledger Setup.
        UpdateGeneralLedgerAndVATPostingSetups(GeneralLedgerSetup, VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPurchaseInvoiceToCreditMemoWithUnrealizedVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        AppliesToDocNo: Code[20];
        DocumentNo: Code[20];
    begin
        // Test to verify Unrealized VAT entry after posting Purchase Credit Memo applied to Purchase Invoice with Unrealized VAT.

        // Setup: Update General Ledger Setup and VAT Posting Setup. Create and Post Purchase Invoice.
        Initialize;
        GeneralLedgerSetup.Get;
        UpdateGeneralLedgerSetup(true, CalcDate('<CY - 1Y>', WorkDate));  // Required for test case to set last date of the previous year to Work Date. True for Unrealized VAT.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."VAT Prod. Posting Group", false, VATPostingSetup."Unrealized VAT Type"::Percentage);  // False for EU Service
        AppliesToDocNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine, PurchaseLine."Document Type"::Invoice, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"), '',
            CreateItem(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(10, 2),
            LibraryRandom.RandDec(100, 2));  // Use Random value for Quantity and Direct Unit Cost, Blank value for Applies To Doc No

        // Exercise: Create and Post Purchase Credit Memo after applying posted Purchase Invoice.
        DocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine2, PurchaseLine2."Document Type"::"Credit Memo", PurchaseLine."Buy-from Vendor No.", AppliesToDocNo,
            PurchaseLine."No.", PurchaseLine.Quantity, PurchaseLine."Direct Unit Cost");

        // Verify: General Ledger entries.
        VATPostingSetup2.Get(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VerifyGLEntries(
          DocumentNo, VATPostingSetup2."Purchase VAT Account", VATPostingSetup2."Purch. VAT Unreal. Account",
          Round(PurchaseLine.Amount * PurchaseLine."VAT %" / 100));

        // Tear Down: Update VAT Posting Setup and General Ledger Setup.
        UpdateGeneralLedgerAndVATPostingSetups(GeneralLedgerSetup, VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceTariffNoOnSalesInvoice()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
        GLAccountNo2: Code[20];
    begin
        // Test to verify Service Tariff No. gets updated on Posted Sales Invoice when VAT Product Posting group is changed on the Sales Invoice Line.

        // Setup: Create Sales Invoice of two lines with different VAT Posting Setup. Update VAT Product Posting groups on two Sales Invoice Lines.
        Initialize;
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."VAT Prod. Posting Group", false, VATPostingSetup."Unrealized VAT Type"::" ");  // False for EU Service.
        GLAccountNo := CreateGLAccount(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);
        LibraryERM.FindVATPostingSetup(VATPostingSetup2, VATPostingSetup2."VAT Calculation Type"::"Reverse Charge VAT");
        UpdateVATPostingSetup(
          VATPostingSetup2."VAT Bus. Posting Group",
          VATPostingSetup2."VAT Prod. Posting Group", true, VATPostingSetup2."Unrealized VAT Type"::" ");  // True for EU Service.
        GLAccountNo2 := CreateGLAccount(VATPostingSetup2, GLAccount."Gen. Posting Type"::Sale);
        CreateSalesInvoiceWithMultipleLines(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", GLAccountNo, GLAccountNo2);
        UpdateVATProductPostingGroupOnSalesLine(SalesHeader."No.", GLAccountNo, VATPostingSetup2."VAT Prod. Posting Group");
        UpdateVATProductPostingGroupOnSalesLine(SalesHeader."No.", GLAccountNo2, VATPostingSetup."VAT Prod. Posting Group");

        // Exercise: Post Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // True for Ship and Invoice

        // Verify: Service Tariff No. gets updated on Posted Sales Invoice Lines.
        VerifyPostedSalesInvoiceLine(DocumentNo, GLAccountNo, SalesHeader."Service Tariff No.");
        VerifyPostedSalesInvoiceLine(DocumentNo, GLAccountNo2, '');  // Blank Service Tariff No. for VAT Posting Setup with EU Service as False

        // Tear Down.
        UpdateVATPostingSetups(VATPostingSetup, VATPostingSetup2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceTariffNoOnServiceInvoice()
    var
        GLAccount: Record "G/L Account";
        ServiceHeader: Record "Service Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        GLAccountNo: Code[20];
        GLAccountNo2: Code[20];
    begin
        // Test to verify Service Tariff No. gets updated on Posted Service Invoice when VAT Product Posting group is changed on the Service Invoice Line.

        // Setup: Create Service Invoice of two lines with different VAT Posting Setup. Update VAT Product Posting groups on two Service Invoice Lines.
        Initialize;
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."VAT Prod. Posting Group", false, VATPostingSetup."Unrealized VAT Type"::" ");
        GLAccountNo := CreateGLAccount(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);
        LibraryERM.FindVATPostingSetup(VATPostingSetup2, VATPostingSetup2."VAT Calculation Type"::"Reverse Charge VAT");
        UpdateVATPostingSetup(
          VATPostingSetup2."VAT Bus. Posting Group",
          VATPostingSetup2."VAT Prod. Posting Group", true, VATPostingSetup2."Unrealized VAT Type"::" ");
        GLAccountNo2 := CreateGLAccount(VATPostingSetup2, GLAccount."Gen. Posting Type"::Sale);
        CreateServiceInvoiceWithMultipleLines(ServiceHeader, VATPostingSetup."VAT Bus. Posting Group", GLAccountNo, GLAccountNo2);
        UpdateVATProductPostingGroupOnServiceLine(ServiceHeader."No.", GLAccountNo, VATPostingSetup2."VAT Prod. Posting Group");
        UpdateVATProductPostingGroupOnServiceLine(ServiceHeader."No.", GLAccountNo2, VATPostingSetup."VAT Prod. Posting Group");

        // Exercise: Post Service Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);  // True for Ship and Invoice

        // Verify: Service Tariff No. gets updated on Posted Service Invoice Lines.
        VerifyPostedServiceInvoiceLine(ServiceHeader."Customer No.", GLAccountNo, ServiceHeader."Service Tariff No.");
        VerifyPostedServiceInvoiceLine(ServiceHeader."Customer No.", GLAccountNo2, '');  // Blank Service Tariff No. for VAT Posting Setup with EU Service as False

        // Tear Down.
        UpdateVATPostingSetups(VATPostingSetup, VATPostingSetup2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceTariffNoOnPurchaseInvoice()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
        GLAccountNo2: Code[20];
    begin
        // Test to verify Service Tariff No. gets updated on Posted Purchase Invoice when VAT Product Posting group is changed on the Purchase Invoice Line.

        // Setup: Create Purchase Invoice of two lines with different VAT Posting Setup. Update VAT Product Posting groups on two Purchase Invoice Lines.
        Initialize;
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."VAT Prod. Posting Group", false, VATPostingSetup."Unrealized VAT Type"::" ");
        GLAccountNo := CreateGLAccount(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        LibraryERM.FindVATPostingSetup(VATPostingSetup2, VATPostingSetup2."VAT Calculation Type"::"Reverse Charge VAT");
        UpdateVATPostingSetup(
          VATPostingSetup2."VAT Bus. Posting Group",
          VATPostingSetup2."VAT Prod. Posting Group", true, VATPostingSetup2."Unrealized VAT Type"::" ");
        GLAccountNo2 := CreateGLAccount(VATPostingSetup2, GLAccount."Gen. Posting Type"::Purchase);
        CreatePurchaseInvoiceWithMultipleLines(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", GLAccountNo, GLAccountNo2);
        UpdateVATProductPostingGroupOnPurchaseLine(PurchaseHeader."No.", GLAccountNo, VATPostingSetup2."VAT Prod. Posting Group");
        UpdateVATProductPostingGroupOnPurchaseLine(PurchaseHeader."No.", GLAccountNo2, VATPostingSetup."VAT Prod. Posting Group");

        // Exercise: Post Purchase Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // True for Receive and Invoice

        // Verify: Service Tariff No. gets updated on Posted Purchase Invoice Lines.
        VerifyPostedPurchaseInvoiceLine(DocumentNo, GLAccountNo, PurchaseHeader."Service Tariff No.");
        VerifyPostedPurchaseInvoiceLine(DocumentNo, GLAccountNo2, '');  // Blank Service Tariff No. for VAT Posting Setup with EU Service as False

        // Tear Down.
        UpdateVATPostingSetups(VATPostingSetup, VATPostingSetup2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountIncludingVATCaptionOnVATSpecificationSubform()
    var
        VATSpecificationSubform: TestPage "VAT Specification Subform";
    begin
        // Test to verify Amount Including VAT field Caption on VAT Specification Subform.

        // Setup.
        Initialize;

        // Exercise: Open VAT Specification Subform.
        VATSpecificationSubform.OpenEdit;

        // Verify: Amount Including VAT field Caption on VAT Specification Subform.
        Assert.AreEqual(StrSubstNo(AmountIncludingVATCap), VATSpecificationSubform."Amount Including VAT".Caption, CaptionMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchNonDeductibleReverseVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchLine: Record "Purchase Line";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        DocNo: Code[20];
    begin
        // Test to verify that 100% Non-Deductible Reverse Charge VAT posted correctly.

        Initialize;
        CreateHundredPctNDReverseChargeVATPostingSetup(VATPostingSetup);
        DocNo := CreatePostPurchInvoiceWithVATSetup(PurchLine, VATPostingSetup);
        VerifyCreditGLEntryExists(
          GLEntry."Document Type"::Invoice, DocNo, VATPostingSetup."Reverse Chrg. VAT Acc.");
        VerifyReverseChargeDeductibleVATEntries(VATEntry."Document Type"::Invoice, DocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCustEntryWithNotExistingAppliesToDocNo()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        // [FEATURE] [Apply] [Sales]
        // [SCENARIO 381909] Stan gets error when trying to post the payment applied to non-existing sales invoice
        Initialize;

        // [GIVEN] Customer Payment line for 100, which applies to not existing Document
        CreatePaymentLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo,
          -LibraryRandom.RandDec(100, 2), LibraryUTUtility.GetNewCode);

        // [GIVEN] Customer Ledger Entry
        CustLedgerEntry.Init;
        CustLedgerEntry."Customer No." := LibrarySales.CreateCustomerNo;
        CustLedgerEntry."Amount to Apply" := GenJournalLine.Amount;
        CustLedgerEntry.Insert;

        // [WHEN] Apply
        asserterror GenJnlPostLine.CustPostApplyCustLedgEntry(GenJournalLine, CustLedgerEntry);

        // [THEN] "There is no Cust. Ledger Entry within the filter." error appears
        Assert.ExpectedError('There is no Cust. Ledger Entry within the filter.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyVendEntryWithNotExistingAppliesToDocNo()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        // [FEATURE] [Apply] [Purchase]
        // [SCENARIO 381909] Stan gets error when trying to post the payment applied to non-existing purchase invoice
        Initialize;

        // [GIVEN] Vendor Payment line for 100, which applies to not existing Document
        CreatePaymentLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo,
          LibraryRandom.RandDec(100, 2), LibraryUTUtility.GetNewCode);

        // [GIVEN] Vendor Ledger Entry
        VendorLedgerEntry.Init;
        VendorLedgerEntry."Vendor No." := LibraryPurchase.CreateVendorNo;
        VendorLedgerEntry."Amount to Apply" := GenJournalLine.Amount;
        VendorLedgerEntry.Insert;

        // [WHEN] Apply
        asserterror GenJnlPostLine.VendPostApplyVendLedgEntry(GenJournalLine, VendorLedgerEntry);

        // [THEN] "There is no Vendor Ledger Entry within the filter." error appears.
        Assert.ExpectedError('There is no Vendor Ledger Entry within the filter.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCustEntryTwice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Apply] [Sales]
        // [SCENARIO 381909] Stan gets error when trying to post the payment applied to closed sales invoice (fully applied).
        Initialize;

        // [GIVEN] Posted Sales Document with "Amount incl. VAT" = 100
        LibraryCashFlowHelper.CreateDefaultSalesOrder(SalesHeader);
        SalesHeader.CalcFields("Amount Including VAT");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Posted payment for 100
        CreatePaymentLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          -SalesHeader."Amount Including VAT", DocumentNo);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Another payment for 100
        CreatePaymentLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          -SalesHeader."Amount Including VAT", DocumentNo);

        // [WHEN] Post the 2nd payment
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] "There is no Cust. Ledger Entry within the filter." error appears
        Assert.ExpectedError('There is no Cust. Ledger Entry within the filter.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyVendEntryTwice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Apply] [Purchase]
        // [SCENARIO 381909] Stan gets error when trying to post the payment applied to closed purchase invoice (fully applied).
        Initialize;

        // [GIVEN] Posted Purchase Document with "Amount incl. VAT" = 100
        LibraryCashFlowHelper.CreateDefaultPurchaseOrder(PurchaseHeader);
        PurchaseHeader.CalcFields("Amount Including VAT");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Posted payment for 100
        CreatePaymentLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.",
          PurchaseHeader."Amount Including VAT", DocumentNo);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Another payment for 100
        CreatePaymentLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.",
          PurchaseHeader."Amount Including VAT", DocumentNo);

        // [WHEN] Post the 2nd payment
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] "There is no Vendor Ledger Entry within the filter." error appears
        Assert.ExpectedError('There is no Vendor Ledger Entry within the filter.');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;
        // Lazy Setup.
        if isInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        isInitialized := true;
        Commit;
    end;

    local procedure CreateAndPostGeneralJournalLine(Type: Option; AccountType: Option; AccountNo: Code[20]; Amount: Decimal; BalAccountNo: Code[20]; AppliesToDocType: Option; AppliesToDocNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalBatch(GenJournalBatch, Type);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Option; VendorNo: Code[20]; AppliesToDocNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Applies-to Doc. Type", PurchaseHeader."Applies-to Doc. Type"::Invoice);
        PurchaseHeader.Validate("Applies-to Doc. No.", AppliesToDocNo);
        UpdateVendorCreditMemoNoOnPurchaseHeader(PurchaseHeader);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, ItemNo, Quantity, DirectUnitCost);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // Post as Invoice
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Option; CustomerNo: Code[20]; AppliesToDocNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Applies-to Doc. Type", SalesHeader."Applies-to Doc. Type"::Invoice);
        SalesHeader.Validate("Applies-to Doc. No.", AppliesToDocNo);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity, UnitPrice);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));  // Post as Invoice
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get;
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Option)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, Type);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateSimpleGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccount(VATPostingSetup: Record "VAT Posting Setup"; GenPostingType: Option): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("Gen. Posting Type", GenPostingType);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateHundredPctNDReverseChargeVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATIdentifier: Record "VAT Identifier";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        LibraryERM.CreateVATIdentifier(VATIdentifier);
        with VATPostingSetup do begin
            Validate("VAT Identifier", VATIdentifier.Code);
            Validate("VAT Calculation Type", "VAT Calculation Type"::"Reverse Charge VAT");
            Validate("VAT %", LibraryRandom.RandInt(10));
            Validate("Deductible %", 0);
            Validate("Purchase VAT Account", CreateSimpleGLAccount);
            Validate("Reverse Chrg. VAT Acc.", CreateSimpleGLAccount);
            Validate("Sales VAT Account", CreateSimpleGLAccount);
            Validate("Nondeductible VAT Account", CreateSimpleGLAccount);
            Modify(true);
        end;
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

    local procedure CreatePaymentLine(var GenJournalLine: Record "Gen. Journal Line"; AccType: Option; No: Code[20]; Amount: Decimal; DocNo: Code[20])
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, AccType, No, Amount);
        GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::Invoice;
        GenJournalLine."Applies-to Doc. No." := DocNo;
        GenJournalLine.Modify;
    end;

    local procedure CreatePostPurchInvoiceWithVATSetup(var PurchLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
        PurchHeader: Record "Purchase Header";
        GLAccNo: Code[20];
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"));
        GLAccNo :=
          CreateGLAccount(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        CreatePurchaseLine(
          PurchHeader, PurchLine, PurchLine.Type::"G/L Account", GLAccNo,
          LibraryRandom.RandInt(10), LibraryRandom.RandDec(100, 2));
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreatePurchaseInvoiceWithMultipleLines(var PurchaseHeader: Record "Purchase Header"; VATBusPostingGroup: Code[20]; No: Code[20]; No2: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(VATBusPostingGroup));
        UpdateVendorCreditMemoNoOnPurchaseHeader(PurchaseHeader);
        CreatePurchaseLine(
          PurchaseHeader, PurchaseLine, PurchaseLine.Type::"G/L Account", No, LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(100, 2));  // Use Random value for Quantity and Direct Unit Cost
        CreatePurchaseLine(
          PurchaseHeader, PurchaseLine, PurchaseLine.Type::"G/L Account", No2, LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(100, 2));  // Use Random value for Quantity and Direct Unit Cost
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Type: Option; No: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceWithMultipleLines(var SalesHeader: Record "Sales Header"; VATBusPostingGroup: Code[20]; No: Code[20]; No2: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(VATBusPostingGroup));
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", No, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));  // Use Random value for Quantity and Unit Price
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", No2, LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(100, 2));  // Use Random value for Quantity and Unit Price
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Option; No: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateServiceInvoiceWithMultipleLines(var ServiceHeader: Record "Service Header"; VATBusPostingGroup: Code[20]; No: Code[20]; No2: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCustomer(VATBusPostingGroup));
        CreateServiceLine(ServiceLine, ServiceHeader, No);
        CreateServiceLine(ServiceLine, ServiceHeader, No2);
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; No: Code[20])
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", No);
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Use Random value for Unit Price
        ServiceLine.Modify(true);
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
    begin
        CompanyInformation.Get;
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure DeletePeriodicSettlementVATEntry(PeriodDate: Date)
    var
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
    begin
        FindPeriodicSettlementVATEntry(PeriodicSettlementVATEntry, PeriodDate);
        PeriodicSettlementVATEntry.Delete(true);
    end;

    local procedure FindPeriodicSettlementVATEntry(var PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry"; PeriodDate: Date)
    begin
        PeriodicSettlementVATEntry.SetRange(
          "VAT Period", Format(Date2DMY(PeriodDate, 3)) + '/' + ConvertStr(Format(Date2DMY(PeriodDate, 2), 2), ' ', '0'));  // Value Zero required for VAT Period.
        PeriodicSettlementVATEntry.FindFirst;
    end;

    local procedure GetStartingDate(): Date
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get;
        exit(CalcDate('<1D>', GeneralLedgerSetup."Last Settlement Date"));  // 1D is required as Starting date for Calc. and Post VAT Settlement report should be the next Day of Last Settlement Date.
    end;

    local procedure RunCalcAndPostVATSettlementReport()
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryVariableStorage.Enqueue(GetStartingDate);
        LibraryVariableStorage.Enqueue(GLAccount."No.");
        Commit;  // Commit required to run the report
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement");
    end;

    local procedure UpdateGeneralLedgerAndVATPostingSetups(GeneralLedgerSetup: Record "General Ledger Setup"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."EU Service", VATPostingSetup."Unrealized VAT Type");
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Unrealized VAT", GeneralLedgerSetup."Last Settlement Date");
    end;

    local procedure UpdateGeneralLedgerSetup(UnrealizedVAT: Boolean; LastSettlementDate: Date)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get;
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Validate("Last Settlement Date", LastSettlementDate);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePeriodicSettlementVATEntry()
    var
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
    begin
        FindPeriodicSettlementVATEntry(PeriodicSettlementVATEntry, WorkDate);
        PeriodicSettlementVATEntry.Validate("VAT Period Closed", false);
        PeriodicSettlementVATEntry.Modify(true);
    end;

    local procedure UpdateVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; EUService: Boolean; UnrealizedVATType: Option)
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", GLAccount."No.");
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", GLAccount."No.");
        VATPostingSetup.Validate("EU Service", EUService);
        VATPostingSetup.Validate("Unrealized VAT Type", UnrealizedVATType);
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateVATPostingSetups(VATPostingSetup: Record "VAT Posting Setup"; VATPostingSetup2: Record "VAT Posting Setup")
    begin
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."EU Service", VATPostingSetup."Unrealized VAT Type");
        UpdateVATPostingSetup(
          VATPostingSetup2."VAT Bus. Posting Group",
          VATPostingSetup2."VAT Prod. Posting Group", VATPostingSetup2."EU Service", VATPostingSetup2."Unrealized VAT Type");
    end;

    local procedure UpdateVATProductPostingGroupOnPurchaseLine(DocumentNo: Code[20]; No: Code[20]; VATProdPostingGroup: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst;
        PurchaseLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateVATProductPostingGroupOnSalesLine(DocumentNo: Code[20]; No: Code[20]; VATProdPostingGroup: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst;
        SalesLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        SalesLine.Modify(true);
    end;

    local procedure UpdateVATProductPostingGroupOnServiceLine(DocumentNo: Code[20]; No: Code[20]; VATProdPostingGroup: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Invoice);
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.SetRange("No.", No);
        ServiceLine.FindFirst;
        ServiceLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        ServiceLine.Modify(true);
    end;

    local procedure UpdateVendorCreditMemoNoOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure VerifyGLEntry(DocumentType: Option; DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst;
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyGLEntries(DocumentNo: Code[20]; GLAccountNo: Code[20]; GLAccountNo2: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        VerifyGLEntry(GLEntry."Document Type"::"Credit Memo", DocumentNo, GLAccountNo, Amount);
        VerifyGLEntry(GLEntry."Document Type"::"Credit Memo", DocumentNo, GLAccountNo2, -Amount);
    end;

    local procedure VerifyCreditGLEntryExists(DocType: Option; DocNo: Code[20]; GLAccNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        with GLEntry do begin
            SetRange("Document Type", DocType);
            SetRange("Document No.", DocNo);
            SetRange("G/L Account No.", GLAccNo);
            Assert.IsTrue(FindFirst, StrSubstNo(EntryDoesNotExistErr, TableCaption, GetFilters));
            Assert.AreEqual(Abs(Amount), "Credit Amount", StrSubstNo(WrongValueErr, TableCaption, FieldCaption("Credit Amount")));
        end;
    end;

    local procedure VerifyReverseChargeDeductibleVATEntries(DocType: Option; DocNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
        ExpectedVATBase: Decimal;
        ExpectedVATAmount: Decimal;
    begin
        with VATEntry do begin
            SetRange("Document Type", DocType);
            SetRange("Document No.", DocNo);
            SetRange(Type, Type::Purchase);
            FindFirst;
            Assert.AreEqual(0, Base, StrSubstNo(WrongValueErr, TableCaption, FieldCaption(Base)));
            Assert.AreEqual(0, Amount, StrSubstNo(WrongValueErr, TableCaption, FieldCaption(Amount)));
            Assert.IsTrue(
              "Nondeductible Base" <> 0, StrSubstNo(WrongValueErr, TableCaption, FieldCaption("Nondeductible Base")));
            Assert.IsTrue(
              "Nondeductible Amount" <> 0, StrSubstNo(WrongValueErr, TableCaption, FieldCaption("Nondeductible Amount")));
            ExpectedVATBase := -"Nondeductible Base";
            ExpectedVATAmount := -"Nondeductible Amount";
            SetRange(Type, Type::Sale);
            FindFirst;
            Assert.AreEqual(0, "Nondeductible Base", StrSubstNo(WrongValueErr, TableCaption, FieldCaption("Nondeductible Base")));
            Assert.AreEqual(0, "Nondeductible Amount", StrSubstNo(WrongValueErr, TableCaption, FieldCaption("Nondeductible Amount")));
            Assert.AreEqual(ExpectedVATBase, Base, StrSubstNo(WrongValueErr, TableCaption, FieldCaption(Base)));
            Assert.AreEqual(ExpectedVATAmount, Amount, StrSubstNo(WrongValueErr, TableCaption, FieldCaption(Amount)));
        end;
    end;

    local procedure VerifyPostedPurchaseInvoiceLine(DocumentNo: Code[20]; No: Code[20]; ServiceTariffNo: Code[10])
    var
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
    begin
        PurchaseInvoiceLine.SetRange("Document No.", DocumentNo);
        PurchaseInvoiceLine.SetRange("No.", No);
        PurchaseInvoiceLine.FindFirst;
        PurchaseInvoiceLine.TestField("Service Tariff No.", ServiceTariffNo);
    end;

    local procedure VerifyPostedSalesInvoiceLine(DocumentNo: Code[20]; No: Code[20]; ServiceTariffNo: Code[10])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange("No.", No);
        SalesInvoiceLine.FindFirst;
        SalesInvoiceLine.TestField("Service Tariff No.", ServiceTariffNo);
    end;

    local procedure VerifyPostedServiceInvoiceLine(CustomerNo: Code[20]; No: Code[20]; ServiceTariffNo: Code[10])
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceLine.SetRange("Customer No.", CustomerNo);
        ServiceInvoiceLine.SetRange("No.", No);
        ServiceInvoiceLine.FindFirst;
        ServiceInvoiceLine.TestField("Service Tariff No.", ServiceTariffNo);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementRequestPageHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    var
        AccountNo: Variant;
        StartingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(AccountNo);
        CalcAndPostVATSettlement.StartingDate.SetValue(StartingDate);
        CalcAndPostVATSettlement.SettlementAcc.SetValue(AccountNo);
        CalcAndPostVATSettlement.GLGainsAccount.SetValue(AccountNo);
        CalcAndPostVATSettlement.GLLossesAccount.SetValue(AccountNo);
        CalcAndPostVATSettlement.DocumentNo.SetValue(AccountNo);
        CalcAndPostVATSettlement.Post.SetValue(true);
        CalcAndPostVATSettlement.ShowVATEntries.SetValue(true);
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyCustomerEntriesModalPageHandler(var UnapplyCustomerEntries: TestPage "Unapply Customer Entries")
    begin
        UnapplyCustomerEntries.Unapply.Invoke;
        UnapplyCustomerEntries.Close;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyVendorEntriesModalPageHandler(var UnapplyVendorEntries: TestPage "Unapply Vendor Entries")
    begin
        UnapplyVendorEntries.Unapply.Invoke;
        UnapplyVendorEntries.Close;
    end;
}

