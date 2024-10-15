codeunit 144015 "IT - Calc. And Post VAT Settl."
{
    // 1. Test to verify Next Period Input VAT should be calculated correctly when there are VAT Entries for the last VAT Posting Setup.
    // 
    // Covers Test cases for Merge Bug:
    // --------------------------------------------------------------------------------------------
    // Test Function                                                                        TFS ID
    // --------------------------------------------------------------------------------------------
    // RunReportCalcAndPostVATSettlement                                                    101186

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure OutputCreditDebitAmountPurchInv()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        PurchAmount: Decimal;
        PostingDate: Date;
    begin
        // Test case verifies Next Period Output VAT/Next Period Input VAT fields on
        // Calc. and Post VAT Settlement report
        // Purchase Invoice with non-deductible Amount
        Initialize;
        PostingDate := GetPostingDate;
        CreateNonDeductibleVATPostingSetup(VATPostingSetup);

        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        PurchAmount := LibraryRandom.RandIntInRange(1000, 10000);
        CreateAndPostPurchInvoice(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          PostingDate, CreateGLAccountWithPostingGroups(VATPostingSetup), PurchAmount);

        RunAndVerifyCalcAndPostVATSettlement(
          PostingDate,
          0,
          CalcDeductVATAmount(PurchAmount, VATPostingSetup."Deductible %", VATPostingSetup."VAT %"),
          VATPostingSetup);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler')]
    [Scope('OnPrem')]
    procedure OutputCreditDebitAmountSalesInv()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        SalesAmt: Decimal;
        PostingDate: Date;
    begin
        // Test case verifies Next Period Output VAT/Next Period Input VAT fields on
        // Calc. and Post VAT Settlement report
        // Sales Invoice
        Initialize;
        PostingDate := GetPostingDate;

        CreateNonDeductibleVATPostingSetup(VATPostingSetup);

        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        SalesAmt := LibraryRandom.RandIntInRange(1000, 10000);
        GLAccount.Get(
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
        CreateAndPostSalesInvoice(Customer, PostingDate, SalesAmt, GLAccount."No.");

        RunAndVerifyCalcAndPostVATSettlement(PostingDate, 0, 0, VATPostingSetup);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure OutputCreditDebitAmountPurchSalesInv()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        Customer: Record Customer;
        DummyGLAccount: Record "G/L Account";
        PurchAmount: Decimal;
        SalesAmount: Decimal;
        GlAccountCode: Code[20];
        PostingDate: Date;
    begin
        // Test case verifies Next Period Output VAT/Next Period Input VAT fields on
        // Calc. and Post VAT Settlement report
        // Purchase Invoice with non-deductible Amount, Sales Invoice with greater Amount
        Initialize;
        PostingDate := GetPostingDate;
        CreateNonDeductibleVATPostingSetup(VATPostingSetup);

        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        PurchAmount := LibraryRandom.RandIntInRange(1000, 10000);
        SalesAmount := PurchAmount * LibraryRandom.RandIntInRange(1, 10);
        GlAccountCode := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, DummyGLAccount."Gen. Posting Type"::Sale);

        CreateAndPostPurchInvoice(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          PostingDate, GlAccountCode, PurchAmount);
        CreateAndPostSalesInvoice(Customer, PostingDate, SalesAmount, GlAccountCode);

        RunAndVerifyCalcAndPostVATSettlement(PostingDate, 0, 0, VATPostingSetup);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure OutputCreditDebitAmountSalesPurchInv()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        Customer: Record Customer;
        DummyGLAccount: Record "G/L Account";
        PurchAmount: Decimal;
        SalesAmount: Decimal;
        SalesInvoiceVATAmount: Decimal;
        GlAccountCode: Code[20];
        PostingDate: Date;
    begin
        // Test case verifies Next Period Output VAT/Next Period Input VAT fields on
        // Calc. and Post VAT Settlement report
        // Purchase Invoice with non-deductible Amount, Sales Invoice with less Amount
        Initialize;
        PostingDate := GetPostingDate;
        CreateNonDeductibleVATPostingSetup(VATPostingSetup);

        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        SalesAmount := LibraryRandom.RandIntInRange(1000, 10000);
        PurchAmount := SalesAmount * LibraryRandom.RandIntInRange(1, 10);
        GlAccountCode := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, DummyGLAccount."Gen. Posting Type"::Sale);
        CreateAndPostPurchInvoice(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          PostingDate, GlAccountCode, PurchAmount);
        SalesInvoiceVATAmount := CreateAndPostSalesInvoice(Customer, PostingDate, SalesAmount, GlAccountCode);

        RunAndVerifyCalcAndPostVATSettlement(
          PostingDate,
          0,
          CalcDeductVATAmount(PurchAmount, VATPostingSetup."Deductible %", VATPostingSetup."VAT %") - SalesInvoiceVATAmount,
          VATPostingSetup);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RunReportCalcAndPostVATSettlement()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        Customer: Record Customer;
        DummyGLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
        UnitPrice: Decimal;
        UnitCost: Decimal;
        PostingDate: Date;
    begin
        // Setup: Find and update VAT Posting Setup. Create Activity Code. Create Vendor and Customer with Activitty Code.
        Initialize;
        PostingDate := GetPostingDate;
        FindAndUpdateVATPostingSetup(VATPostingSetup);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, DummyGLAccount."Gen. Posting Type"::Sale);
        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));

        // Create and post Purchase Invoice. Create and Post Sales Invoice.
        UnitPrice := LibraryRandom.RandInt(100);
        UnitCost := UnitPrice + LibraryRandom.RandIntInRange(5, 10); // Make sure Input VAT is greater than Output VAT to trigger this bug.
        CreateAndPostPurchInvoice(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          PostingDate, GLAccountNo, UnitCost);
        CreateAndPostSalesInvoice(Customer, PostingDate, UnitPrice, GLAccountNo);

        // Exercise: Run Report Calc. and Post VAT Settlement.
        // Verify: Verify the "Next Period Input VAT" equals "Input VAT" - "Output VAT".
        RunAndVerifyCalcAndPostVATSettlement(
          PostingDate, 0, (UnitCost - UnitPrice) * VATPostingSetup."VAT %" / 100, VATPostingSetup);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RunReportCalcAndPostVATSettlementWithReverseVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        DummyGLAccount: Record "G/L Account";
        GLSetup: Record "General Ledger Setup";
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
        PostingDate: Date;
        Price: Integer;
        ExpectedVATAmount: Decimal;
    begin
        // [FEATURE] [VAT Settlement] [Reverse Charge VAT]
        // [SCENARIO 275693] Reverse Charge VAT Entries must be posted to Reverse Chrg. VAT Acc. after posting throught Calc. And Post VAT Settlement report
        Initialize;

        // [GIVEN] VAT Posting Setup with Reverse Chrg. VAT Acc. = "GLAcc"
        PostingDate := GetPostingDate;
        CreateVATPostingSetupWithReverseChrgVATAcc(VATPostingSetup);
        Price := LibraryRandom.RandIntInRange(100, 1000);
        ExpectedVATAmount := Round(Price * VATPostingSetup."VAT %" / 100, GLSetup."Amount Rounding Precision");

        // [GIVEN] Posted Purchase Invoice
        CreateAndPostPurchInvoice(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"), PostingDate,
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, DummyGLAccount."Gen. Posting Type"::Sale),
          Price);

        // [WHEN] Run "Calc. and Post VAT Settlement"
        LibraryVariableStorage.Enqueue(PostingDate);
        CalcAndPostVATSettlement.SetTableView(VATPostingSetup);
        CalcAndPostVATSettlement.InitializeRequest(
          PostingDate, PostingDate, PostingDate, Format(LibraryRandom.RandIntInRange(1, 10)), LibraryERM.CreateGLAccountNo,
          LibraryERM.CreateGLAccountNo, LibraryERM.CreateGLAccountNo, false, true);
        Commit;
        CalcAndPostVATSettlement.Run;

        // [THEN] There is one record of "G/L Entry" for G/L Account - "Reverse Chrg. VAT Acc." and "Gen. Posting Type" = "Settlement"
        GLEntry.SetRange("G/L Account No.", VATPostingSetup."Reverse Chrg. VAT Acc.");
        GLEntry.SetRange("Gen. Posting Type", GLEntry."Gen. Posting Type"::Settlement);
        GLEntry.FindFirst;
        GLEntry.TestField("Debit Amount", ExpectedVATAmount);

        // [THEN] There is one record of "G/L Entry" for G/L Account - "Purchase VAT Account" and "Gen. Posting Type" = "Settlement"
        GLEntry.SetRange("G/L Account No.", VATPostingSetup."Purchase VAT Account");
        GLEntry.FindFirst;
        GLEntry.TestField("Credit Amount", ExpectedVATAmount);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure NextPeriodInVATSettlementReportWithSetPlafondPeriod()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
        ActivityCode: Code[10];
        GLAccountCode: Code[20];
        PurchAmount: Decimal;
    begin
        // [FEATURE] [Report] [VAT Settlement]
        // [SCENARIO 323097] 'Next Period Output/Input VAT' fields are present in Calc. and Post VAT Settlement report
        Initialize;

        // [GIVEN] Set VAT Plafond Period
        InitLastSettlementDate(CalcDate('<1M-1D>', CalcDate('<-CY-1Y>', WorkDate)));
        InitVATPlafondPeriod(CalcDate('<-CY-1Y>', WorkDate), 0);

        // [GIVEN] Set VAT Posting Setup with 'Deductible %'=20 and 'VAT %'=10, created G/L Account
        CreateNonDeductibleVATPostingSetupAndGroups(VATPostingSetup);
        GLAccountCode := CreateGLAccountWithPostingGroups(VATPostingSetup);

        // [GIVEN] Created and posted Purchase Invoice for this period wth Amount=100
        LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        PurchAmount := LibraryRandom.RandDecInRange(100, 1000, 2);
        CreateAndPostPurchInvoice(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          CalcDate('<+1M+1D>', CalcDate('<-CY-1Y>', WorkDate)), GLAccountCode, PurchAmount);

        // [GIVEN] Initialized Calc. and Post VAT Settlement report
        VATPostingSetup.SetRecFilter;
        CalcAndPostVATSettlement.SetTableView(VATPostingSetup);
        CalcAndPostVATSettlement.InitializeRequest(
          CalcDate('<1M>', CalcDate('<-CY-1Y>', WorkDate)),
          CalcDate('<2M-1D>', CalcDate('<-CY-1Y>', WorkDate)),
          CalcDate('<2M-1D>', CalcDate('<-CY-1Y>', WorkDate)),
          '',
          GLAccountCode, GLAccountCode, GLAccountCode, true, false);

        // [WHEN] Run Calc. and Post VAT Settlement report
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);
        CalcAndPostVATSettlement.SaveAsExcel(LibraryReportValidation.GetFileName);

        // [THEN] In the report 'Next Period Input VAT'=2 and 'Next Period Output VAT'=0
        VerifyCalcAndPostVATSettlementReportCreditDebitExistence(
          0, CalcDeductVATAmount(PurchAmount, VATPostingSetup."Deductible %", VATPostingSetup."VAT %"));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
    end;

    local procedure InitLastSettlementDate(InitialDate: Date)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        with GeneralLedgerSetup do begin
            Get;
            "Last Settlement Date" := CalcDate('<1M>', InitialDate);
            Modify;
        end;
    end;

    local procedure InitVATPlafondPeriod(InitialDate: Date; CalculatedAmount: Decimal)
    var
        VATPlafondPeriod: Record "VAT Plafond Period";
    begin
        with VATPlafondPeriod do begin
            DeleteAll;
            Init;
            Year := Date2DMY(InitialDate, 3);
            Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
            "Calculated Amount" := CalculatedAmount;
            Insert;
        end;
    end;

    local procedure CreateGLAccountWithPostingGroups(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.FindGenProductPostingGroup(GenProdPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        with GLAccount do begin
            Validate("Gen. Posting Type", "Gen. Posting Type"::Sale);
            Validate("Gen. Prod. Posting Group", GenProdPostingGroup.Code);
            Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            Modify(true);
        end;
        exit(GLAccount."No.");
    end;

    local procedure CreateNonDeductibleVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 30));
        VATPostingSetup.Validate("Deductible %", LibraryRandom.RandIntInRange(10, 90));
        LibraryERM.CreateGLAccount(GLAccount);
        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Modify(true);

        VATBusPostingGroup.Get(VATPostingSetup."VAT Bus. Posting Group");
        NoSeriesLinePurchase.SetRange("Series Code", VATBusPostingGroup."Default Purch. Operation Type");
        NoSeriesLinePurchase.ModifyAll("Last Date Used", 0D);
    end;

    local procedure CreateNonDeductibleVATPostingSetupAndGroups(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);
        LibraryERM.CreateGLAccount(GLAccount);
        VATPostingSetup.Validate("Deductible %", LibraryRandom.RandDec(20, 2));
        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Modify(true);

        NoSeriesLinePurchase.SetRange("Series Code", VATBusPostingGroup."Default Purch. Operation Type");
        NoSeriesLinePurchase.ModifyAll("Last Date Used", 0D);
    end;

    local procedure CreateAndPostPurchInvoice(VendorNo: Code[20]; PostingDate: Date; GLAccountNo: Code[20]; UnitCost: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Document Date", PostingDate);
        PurchaseHeader.Validate("Operation Occurred Date", PostingDate);
        PurchaseHeader."Posting No. Series" := LibraryERM.CreateNoSeriesPurchaseCode;
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify;
        PurchaseHeader.Validate("Check Total", PurchaseLine."Amount Including VAT");
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesInvoice(Customer: Record Customer; PostingDate: Date; UnitPrice: Decimal; GLAccountNo: Code[20]): Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NoSeries: Record "No. Series";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Document Date", PostingDate);
        SalesHeader.Validate("Operation Occurred Date", PostingDate);
        SalesHeader.Validate("Posting Date", PostingDate);
        NoSeries.Init;
        SalesHeader.Validate("Operation Type", LibraryERM.FindOperationType(NoSeries."No. Series Type"::Sales));
        SalesHeader."Posting No. Series" := LibraryERM.CreateNoSeriesSalesCode;
        SalesHeader.Modify;

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, 1);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify;
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesLine."Amount Including VAT" - SalesLine.Amount);
    end;

    local procedure FindAndUpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        with VATPostingSetup do begin
            SetRange("Deductible %", 100);
            FindLast;
            if "VAT %" = 0 then begin
                Validate("VAT %", LibraryRandom.RandInt(10));
                Modify(true);
            end;
        end;
    end;

    local procedure CreateVATPostingSetupWithReverseChrgVATAcc(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        GLAccount: Record "G/L Account";
        NoSeriesLineSales: Record "No. Series Line Sales";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(10, 50));
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet";
        GLAccount.Modify;
        VATPostingSetup."Reverse Chrg. VAT Acc." := GLAccount."No.";
        VATPostingSetup.Modify;
        VATBusinessPostingGroup.Get(VATPostingSetup."VAT Bus. Posting Group");
        NoSeriesLineSales.SetRange("Series Code", VATBusinessPostingGroup."Default Sales Operation Type");
        NoSeriesLineSales.ModifyAll("Last Date Used", 0D);
    end;

    local procedure VerifyCalcAndPostVATStatementDebitCredit(DebitNextPeriodAmount: Decimal; CreditNextPeriodAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.GetLastRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('DebitNextPeriod', DebitNextPeriodAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('CreditNextPeriod', CreditNextPeriodAmount);
    end;

    local procedure GetPostingDate(): Date
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get;
        exit(CalcDate('<+1D>', GeneralLedgerSetup."Last Settlement Date"))
    end;

    local procedure RunAndVerifyCalcAndPostVATSettlement(PostingDate: Date; CreditNextPeriodAmount: Decimal; DebitNextPeriodAmount: Decimal; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryVariableStorage.Enqueue(PostingDate);
        VATPostingSetup.SetRecFilter;
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement", true, false, VATPostingSetup);

        VerifyCalcAndPostVATStatementDebitCredit(CreditNextPeriodAmount, DebitNextPeriodAmount);
    end;

    local procedure CalcDeductVATAmount(Amount: Decimal; DeductPct: Decimal; VATPct: Decimal): Decimal
    begin
        exit(Round(Amount * (DeductPct / 100) * (VATPct / 100)));
    end;

    local procedure VerifyCalcAndPostVATSettlementReportCreditDebitExistence(CreditNextPeriodAmount: Decimal; DebitNextPeriodAmount: Decimal)
    var
        OutputVAT: Text;
        OutputVATFound: Boolean;
        InputVAT: Text;
        InputVATFound: Boolean;
    begin
        LibraryReportValidation.DownloadFile;
        LibraryReportValidation.OpenExcelFile;

        OutputVAT := LibraryReportValidation.GetValueAt(OutputVATFound,
            LibraryReportValidation.FindRowNoFromColumnCaption('Next Period Output VAT'),
            LibraryReportValidation.FindColumnNoFromColumnCaption('Next Period Output VAT') + 9);
        Assert.IsTrue(OutputVATFound, '');
        Assert.AreEqual(Format(CreditNextPeriodAmount), OutputVAT, '');

        InputVAT := LibraryReportValidation.GetValueAt(InputVATFound,
            LibraryReportValidation.FindRowNoFromColumnCaption('Next Period Input VAT'),
            LibraryReportValidation.FindColumnNoFromColumnCaption('Next Period Input VAT') + 9);
        Assert.IsTrue(InputVATFound, '');
        Assert.AreEqual(Format(DebitNextPeriodAmount), InputVAT, '');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    begin
        CalcAndPostVATSettlement.StartingDate.SetValue := LibraryVariableStorage.DequeueDate;
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

