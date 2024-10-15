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
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in %3', Comment = '%1 = Field Caption , %2 = Expected Value , %3 = Table Caption';

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
        Initialize();
        PostingDate := GetPostingDate();
        CreateNonDeductibleVATPostingSetup(VATPostingSetup);

        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        PurchAmount := LibraryRandom.RandIntInRange(1000, 10000);
        CreateAndPostPurchInvoice(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          PostingDate, CreateGLAccountWithPostingGroups(VATPostingSetup), PurchAmount, '');

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
        Initialize();
        PostingDate := GetPostingDate();

        CreateNonDeductibleVATPostingSetup(VATPostingSetup);

        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        SalesAmt := LibraryRandom.RandIntInRange(1000, 10000);
        GLAccount.Get(
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
        CreateAndPostSalesInvoice(Customer, PostingDate, SalesAmt, GLAccount."No.", '');

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
        Initialize();
        PostingDate := GetPostingDate();
        CreateNonDeductibleVATPostingSetup(VATPostingSetup);

        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        PurchAmount := LibraryRandom.RandIntInRange(1000, 10000);
        SalesAmount := PurchAmount * LibraryRandom.RandIntInRange(1, 10);
        GlAccountCode := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, DummyGLAccount."Gen. Posting Type"::Sale);

        CreateAndPostPurchInvoice(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          PostingDate, GlAccountCode, PurchAmount, '');
        CreateAndPostSalesInvoice(Customer, PostingDate, SalesAmount, GlAccountCode, '');

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
        Initialize();
        PostingDate := GetPostingDate();
        CreateNonDeductibleVATPostingSetup(VATPostingSetup);

        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        SalesAmount := LibraryRandom.RandIntInRange(1000, 10000);
        PurchAmount := SalesAmount * LibraryRandom.RandIntInRange(1, 10);
        GlAccountCode := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, DummyGLAccount."Gen. Posting Type"::Sale);
        CreateAndPostPurchInvoice(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          PostingDate, GlAccountCode, PurchAmount, '');
        SalesInvoiceVATAmount := CreateAndPostSalesInvoice(Customer, PostingDate, SalesAmount, GlAccountCode, '');

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
        Initialize();
        PostingDate := GetPostingDate();
        FindAndUpdateVATPostingSetup(VATPostingSetup);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, DummyGLAccount."Gen. Posting Type"::Sale);
        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));

        // Create and post Purchase Invoice. Create and Post Sales Invoice.
        UnitPrice := LibraryRandom.RandInt(100);
        UnitCost := UnitPrice + LibraryRandom.RandIntInRange(5, 10); // Make sure Input VAT is greater than Output VAT to trigger this bug.
        CreateAndPostPurchInvoice(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          PostingDate, GLAccountNo, UnitCost, '');
        CreateAndPostSalesInvoice(Customer, PostingDate, UnitPrice, GLAccountNo, '');

        // Exercise: Run Report Calc. and Post VAT Settlement.
        // Verify: Verify the "Next Period Input VAT" equals "Input VAT" - "Output VAT".
        RunAndVerifyCalcAndPostVATSettlement(
          PostingDate, 0, (UnitCost - UnitPrice) * VATPostingSetup."VAT %" / 100, VATPostingSetup);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RunReportCalcAndPostVATSettlementWithActivityCode()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        Customer: Record Customer;
        DummyGLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
        ActivityCode: Code[6];
        UnitPrice: Decimal;
        UnitCost: Decimal;
        PostingDate: Date;
    begin
        // [SCENARIO 333516] When Use Activity Code is enabled in General Setup, calc and post vat settlement works
        Initialize();
        // [GIVEN] Use Activity Code enabled
        SetUseActivityCode(true);
        ActivityCode := CreateActivityCode();
        // [GIVEN] Prepare setup for posting of a sales and purchase invoices
        PostingDate := GetPostingDate();
        FindAndUpdateVATPostingSetup(VATPostingSetup);
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, DummyGLAccount."Gen. Posting Type"::Sale);
        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));

        // [GIVEN] Create and Post Purchase and Sales Invoices.
        UnitPrice := LibraryRandom.RandInt(100);
        UnitCost := UnitPrice + LibraryRandom.RandIntInRange(5, 10); // Make sure Input VAT is greater than Output VAT to trigger this bug.
        CreateAndPostPurchInvoice(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          PostingDate, GLAccountNo, UnitCost, ActivityCode);
        CreateAndPostSalesInvoice(Customer, PostingDate, UnitPrice, GLAccountNo, ActivityCode);

        // [WHEN] Run Report Calc. and Post VAT Settlement.
        // [THEN] Verify the "Next Period Input VAT" equals "Input VAT" - "Output VAT".
        RunAndVerifyCalcAndPostVATSettlement(
          PostingDate, 0, (UnitCost - UnitPrice) * VATPostingSetup."VAT %" / 100, VATPostingSetup);

        // Clean up.
        SetUseActivityCode(false);
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
        Initialize();

        // [GIVEN] VAT Posting Setup with Reverse Chrg. VAT Acc. = "GLAcc"
        PostingDate := GetPostingDate();
        CreateVATPostingSetupWithReverseChrgVATAcc(VATPostingSetup);
        Price := LibraryRandom.RandIntInRange(100, 1000);
        ExpectedVATAmount := Round(Price * VATPostingSetup."VAT %" / 100, GLSetup."Amount Rounding Precision");

        // [GIVEN] Posted Purchase Invoice
        CreateAndPostPurchInvoice(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"), PostingDate,
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, DummyGLAccount."Gen. Posting Type"::Sale),
          Price, '');

        // [WHEN] Run "Calc. and Post VAT Settlement"
        LibraryVariableStorage.Enqueue(PostingDate);
        CalcAndPostVATSettlement.SetTableView(VATPostingSetup);
        CalcAndPostVATSettlement.InitializeRequest(
          PostingDate, PostingDate, PostingDate, Format(LibraryRandom.RandIntInRange(1, 10)), LibraryERM.CreateGLAccountNo(),
          LibraryERM.CreateGLAccountNo(), LibraryERM.CreateGLAccountNo(), false, true);
        Commit();
        CalcAndPostVATSettlement.Run();

        // [THEN] There is one record of "G/L Entry" for G/L Account - "Reverse Chrg. VAT Acc." and "Gen. Posting Type" = "Settlement"
        GLEntry.SetRange("G/L Account No.", VATPostingSetup."Reverse Chrg. VAT Acc.");
        GLEntry.SetRange("Gen. Posting Type", GLEntry."Gen. Posting Type"::Settlement);
        GLEntry.FindFirst();
        GLEntry.TestField("Debit Amount", ExpectedVATAmount);

        // [THEN] There is one record of "G/L Entry" for G/L Account - "Purchase VAT Account" and "Gen. Posting Type" = "Settlement"
        GLEntry.SetRange("G/L Account No.", VATPostingSetup."Purchase VAT Account");
        GLEntry.FindFirst();
        GLEntry.TestField("Credit Amount", ExpectedVATAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure NextPeriodInVATSettlementReportWithSetPlafondPeriod()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
        GLAccountCode: Code[20];
        PurchAmount: Decimal;
    begin
        // [FEATURE] [Report] [VAT Settlement]
        // [SCENARIO 323097] 'Next Period Output/Input VAT' fields are present in Calc. and Post VAT Settlement report
        Initialize();

        // [GIVEN] Set VAT Plafond Period
        InitLastSettlementDate(CalcDate('<1M-1D>', CalcDate('<-CY-1Y>', WorkDate())));
        InitVATPlafondPeriod(CalcDate('<-CY-1Y>', WorkDate()), 0);

        // [GIVEN] Set VAT Posting Setup with 'Deductible %'=20 and 'VAT %'=10, created G/L Account
        CreateNonDeductibleVATPostingSetupAndGroups(VATPostingSetup);
        GLAccountCode := CreateGLAccountWithPostingGroups(VATPostingSetup);

        // [GIVEN] Created and posted Purchase Invoice for this period wth Amount=100
        LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        PurchAmount := LibraryRandom.RandDecInRange(100, 1000, 2);
        CreateAndPostPurchInvoice(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          CalcDate('<+1M+1D>', CalcDate('<-CY-1Y>', WorkDate())), GLAccountCode, PurchAmount, '');

        // [GIVEN] Initialized Calc. and Post VAT Settlement report
        VATPostingSetup.SetRecFilter();
        CalcAndPostVATSettlement.SetTableView(VATPostingSetup);
        CalcAndPostVATSettlement.InitializeRequest(
          CalcDate('<1M>', CalcDate('<-CY-1Y>', WorkDate())),
          CalcDate('<2M-1D>', CalcDate('<-CY-1Y>', WorkDate())),
          CalcDate('<2M-1D>', CalcDate('<-CY-1Y>', WorkDate())),
          '',
          GLAccountCode, GLAccountCode, GLAccountCode, true, false);

        // [WHEN] Run Calc. and Post VAT Settlement report
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        CalcAndPostVATSettlement.SaveAsExcel(LibraryReportValidation.GetFileName());

        // [THEN] In the report 'Next Period Input VAT'=2 and 'Next Period Output VAT'=0
        VerifyCalcAndPostVATSettlementReportCreditDebitExistence(
          0, CalcDeductVATAmount(PurchAmount, VATPostingSetup."Deductible %", VATPostingSetup."VAT %"));
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckCorrectInputOfAdvancedAmount()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
        PurchAmount: Decimal;
        AdvancedAmount: Decimal;
        PostingDate: Date;
        VATPeriod: Code[10];
    begin
        // [FEATURE] [Report] [VAT Settlement]
        // [SCENARIO 348067] Run "Calc And Post VAT Settlement" with Advanced Amount
        Initialize();

        // [GIVEN] Created Posting Date and VAT Posting Setup
        PostingDate := GetPostingDate();
        PeriodicSettlementVATEntry.Modifyall("VAT Period Closed", true);
        SetupVATPeriod(PostingDate, VATPeriod);
        CreateNonDeductibleVATPostingSetup(VATPostingSetup);

        // [GIVEN] Created and posted purchase incoice
        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        PurchAmount := LibraryRandom.RandIntInRange(1000, 10000);
        CreateAndPostPurchInvoice(
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          PostingDate, CreateGLAccountWithPostingGroups(VATPostingSetup), PurchAmount, '');

        // [GIVEN] Set Advanced Amount in last period in Periodic Settlement VAT Entry
        AdvancedAmount := LibraryRandom.RandDec(5000, 2);
        PeriodicSettlementVATEntry.Get(VATPeriod);
        PeriodicSettlementVATEntry.Validate("Advanced Amount", AdvancedAmount);
        PeriodicSettlementVATEntry.Modify();
        Commit();

        // [WHEN] Run the report "Calc. and Post VAT Settlement"
        LibraryVariableStorage.Enqueue(PostingDate);
        VATPostingSetup.SetRecFilter();
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement", true, false, VATPostingSetup);

        // [THEN] Verify the "PeriodInputVATYearInputVAT" suggest Advanced Amount
        // [THEN] Verify the "DebitNextPeriod" do not suggest Advanced Amount
        // [THEN] Verify the "CreditNextPeriod" suggest Advanced Amount
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('PeriodInputVATYearInputVAT', AdvancedAmount);
        LibraryReportDataset.AssertElementWithValueExists('DebitNextPeriod', 0);
        LibraryReportDataset.AssertElementWithValueExists(
            'CreditNextPeriod', CalcDeductVATAmount(PurchAmount, VATPostingSetup."Deductible %", VATPostingSetup."VAT %") + AdvancedAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VerifyVATSettlementWithZeroVATInCurrentPeriodIfPreviousPeriodHasCreditAmount()
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
        PurchAmount: Decimal;
        ExpectedVATAmount: Decimal;
        VATPeriod: Code[10];
    begin
        // [SCENARIO 477305] Verify VAT settlement when you "calculate and Post a VAT Settlement" for a month with a zero VAT amount 
        // and the previous period only had a credit amount.
        Initialize();

        // [GIVEN] Update the Last Settlement Date in General Ledger Setup.
        InitLastSettlementDate(CalcDate('<1M-1D>', CalcDate('<-CY-1Y>', WorkDate())));

        // [GIVEN] Delete the Periodic Settlement VAT Entry.
        PeriodicSettlementVATEntry.DeleteAll();

        // [GIVEN] Create VAT Posting Setup.
        CreateNonDeductibleVATPostingSetup(VATPostingSetup);

        // [GIVEN] Create a vendor with the VAT Bus Posting Group.
        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));

        // [GIVEN] Generate a random Purchase Amount.
        PurchAmount := LibraryRandom.RandIntInRange(1000, 2000);

        // [GIVEN] Create and post Purchase Incoice with VAT Bus. Posting Group.
        CreateAndPostPurchInvoice(
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
            GetPostingDate(), CreateGLAccountWithPostingGroups(VATPostingSetup), PurchAmount, '');

        // [GIVEN] Save a transaction.
        Commit();

        // [GIVEN] Find Posted VAT Entry.
        VATEntry.FindLast();

        // [GIVEN] Save Expected VAT Amount.
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."Settlement Round. Factor" <> 0 then
            ExpectedVATAmount := Round(VATEntry.Amount, GeneralLedgerSetup."Settlement Round. Factor");

        // [GIVEN] Run the report "Calc. and Post VAT Settlement"
        LibraryVariableStorage.Enqueue(GetPostingDate());
        VATPostingSetup.SetRecFilter();
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement", true, false, VATPostingSetup);

        // [WHEN] Run the report "Calc. and Post VAT Settlement" with Zero Amount in the current period.
        VATPeriod := Format(Date2DMY(GetPostingDate(), 3)) + '/' + ConvertStr(Format(Date2DMY(GetPostingDate(), 2), 2), ' ', '0');
        LibraryVariableStorage.Enqueue(GetPostingDate());
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement", true, false, VATPostingSetup);

        // [Verify] Verify the VAT Settlement amount in the periodic settlement VAT Entry.
        PeriodicSettlementVATEntry.Get(VATPeriod);
        Assert.AreEqual(
            ExpectedVATAmount,
            PeriodicSettlementVATEntry."VAT Settlement",
            StrSubstNo(
                ValueMustBeEqualErr,
                PeriodicSettlementVATEntry.FieldCaption("VAT Settlement"),
                ExpectedVATAmount,
                PeriodicSettlementVATEntry.TableCaption()));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure InitLastSettlementDate(InitialDate: Date)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Last Settlement Date" := CalcDate('<1M>', InitialDate);
        GeneralLedgerSetup.Modify();
    end;

    local procedure SetUseActivityCode(NewValue: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Use Activity Code", NewValue);
        GeneralLedgerSetup.Modify();
    end;

    local procedure InitVATPlafondPeriod(InitialDate: Date; CalculatedAmount: Decimal)
    var
        VATPlafondPeriod: Record "VAT Plafond Period";
    begin
        VATPlafondPeriod.DeleteAll();
        VATPlafondPeriod.Init();
        VATPlafondPeriod.Year := Date2DMY(InitialDate, 3);
        VATPlafondPeriod.Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        VATPlafondPeriod."Calculated Amount" := CalculatedAmount;
        VATPlafondPeriod.Insert();
    end;

    local procedure CreateGLAccountWithPostingGroups(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.FindGenProductPostingGroup(GenProdPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup.Code);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateNonDeductibleVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        NoSeriesLine: Record "No. Series Line";
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
        NoSeriesLine.SetRange("Series Code", VATBusPostingGroup."Default Purch. Operation Type");
        NoSeriesLine.ModifyAll("Last Date Used", 0D);
    end;

    local procedure CreateNonDeductibleVATPostingSetupAndGroups(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        NoSeriesLine: Record "No. Series Line";
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

        NoSeriesLine.SetRange("Series Code", VATBusPostingGroup."Default Purch. Operation Type");
        NoSeriesLine.ModifyAll("Last Date Used", 0D);
    end;

    local procedure CreateAndPostPurchInvoice(VendorNo: Code[20]; PostingDate: Date; GLAccountNo: Code[20]; UnitCost: Decimal; ActivityCode: Code[6])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Document Date", PostingDate);
        PurchaseHeader.Validate("Operation Occurred Date", PostingDate);
        PurchaseHeader.Validate("Activity Code", ActivityCode);
        PurchaseHeader."Posting No. Series" := LibraryERM.CreateNoSeriesPurchaseCode();
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify();
        PurchaseHeader.Validate("Check Total", PurchaseLine."Amount Including VAT");
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesInvoice(Customer: Record Customer; PostingDate: Date; UnitPrice: Decimal; GLAccountNo: Code[20]; ActivityCode: Code[6]): Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NoSeries: Record "No. Series";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Document Date", PostingDate);
        SalesHeader.Validate("Operation Occurred Date", PostingDate);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Activity Code", ActivityCode);
        NoSeries.Init();
        SalesHeader.Validate("Operation Type", LibraryERM.FindOperationType(NoSeries."No. Series Type"::Sales));
        SalesHeader."Posting No. Series" := LibraryERM.CreateNoSeriesSalesCode();
        SalesHeader.Modify();

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, 1);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesLine."Amount Including VAT" - SalesLine.Amount);
    end;

    local procedure FindAndUpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Deductible %", 100);
        VATPostingSetup.FindLast();
        if VATPostingSetup."VAT %" = 0 then begin
            VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(10));
            VATPostingSetup.Modify(true);
        end;
    end;

    local procedure CreateVATPostingSetupWithReverseChrgVATAcc(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        GLAccount: Record "G/L Account";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(10, 50));
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet";
        GLAccount.Modify();
        VATPostingSetup."Reverse Chrg. VAT Acc." := GLAccount."No.";
        VATPostingSetup.Modify();
        VATBusinessPostingGroup.Get(VATPostingSetup."VAT Bus. Posting Group");
        NoSeriesLine.SetRange("Series Code", VATBusinessPostingGroup."Default Sales Operation Type");
        NoSeriesLine.ModifyAll("Last Date Used", 0D);
    end;

    local procedure VerifyCalcAndPostVATStatementDebitCredit(DebitNextPeriodAmount: Decimal; CreditNextPeriodAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetLastRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('DebitNextPeriod', DebitNextPeriodAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('CreditNextPeriod', CreditNextPeriodAmount);
    end;

    local procedure CreateActivityCode(): Code[10]
    var
        ActivityCode: Record "Activity Code";
    begin
        ActivityCode.Init();
        ActivityCode.Validate(
          Code,
          CopyStr(LibraryUtility.GenerateRandomCode(ActivityCode.FieldNo(Code), DATABASE::"Activity Code"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Activity Code", ActivityCode.FieldNo(Code))));
        ActivityCode.Insert(true);
        ActivityCode.Validate(Description, ActivityCode.Code); // Validating description with code as value is not important.
        ActivityCode.Modify(true);
        exit(ActivityCode.Code);
    end;

    local procedure GetPostingDate(): Date
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(CalcDate('<+1D>', GeneralLedgerSetup."Last Settlement Date"))
    end;

    local procedure RunAndVerifyCalcAndPostVATSettlement(PostingDate: Date; CreditNextPeriodAmount: Decimal; DebitNextPeriodAmount: Decimal; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryVariableStorage.Enqueue(PostingDate);
        VATPostingSetup.SetRecFilter();
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
        LibraryReportValidation.DownloadFile();
        LibraryReportValidation.OpenExcelFile();

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

    local procedure SetupVATPeriod(PostingDate: Date; var VATPeriod: Code[10])
    var
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
    begin
        VatPeriod :=
            Format(Date2DMY(CalcDate('<1M>', PostingDate), 3)) + '/' +
            ConvertStr(Format(Date2DMY(CalcDate('<1M>', PostingDate), 2), 2), ' ', '0');
        PeriodicSettlementVATEntry.Get(VatPeriod);
        PeriodicSettlementVATEntry.Delete();
        VatPeriod :=
            Format(Date2DMY(PostingDate, 3)) + '/' +
            ConvertStr(Format(Date2DMY(PostingDate, 2), 2), ' ', '0');
        PeriodicSettlementVATEntry.Get(VatPeriod);
        PeriodicSettlementVATEntry.Validate("VAT Period Closed", false);
        PeriodicSettlementVATEntry.Modify(TRUE);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    begin
        CalcAndPostVATSettlement.StartingDate.SetValue := LibraryVariableStorage.DequeueDate();
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

