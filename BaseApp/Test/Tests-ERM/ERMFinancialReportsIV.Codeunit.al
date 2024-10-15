codeunit 134992 "ERM Financial Reports IV"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [ERM]
        IsInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        PostingDateErr: Label 'Enter the posting date.';
        VATGLAccountErr: Label 'There is one or more VAT Entries with no G/L Account defined in the selected period. Please exclude these VAT entries or ask your partner to help you fix this data issue.';
        DocumentNoErr: Label 'Enter the document no.';
        SettlementAccountErr: Label 'Enter the settlement account';
        IsInitialized: Boolean;
        SameAmountErr: Label 'Amount must be same.';
        NoDataRowErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2', Comment = '%1 = Element Name, %2 = Element Value';
        TooManyWorksheetsErr: Label 'Expected single worksheet';

    [Test]
    [HandlerFunctions('RHVATStatement')]
    [Scope('OnPrem')]
    procedure VATStatementWithOpenEntriesPurchase()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        Selection: Enum "VAT Statement Report Selection";
    begin
        // Test VAT Statement Report for Purchase with Open VAT Entries.

        // Setup: Create and Post General Journal Line for Vendor, Taking -1 for negative sign factor.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostGeneralJournalLine(
          VATPostingSetup, GenJournalLine."Account Type"::Vendor, Vendor."No.", GenJournalLine."Gen. Posting Type"::Purchase, -1, true);

        // Save VAT Statement Report for Purchase with Open Selection and Verify the Amount. Passing FALSE to find Open Entries for Purchase.
        // Exercise And Verification done in VATStatementForDifferentEntries function.
        VATStatementForDifferentEntries(VATPostingSetup, GenJournalLine."Gen. Posting Type"::Purchase, Selection::Open, false);
    end;

    [Test]
    [HandlerFunctions('RHVATStatement')]
    [Scope('OnPrem')]
    procedure VATStatementWithOpenEntriesSales()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Selection: Enum "VAT Statement Report Selection";
    begin
        // Test VAT Statement Report for Sales with Open VAT Entries.

        // Setup: Create and Post General Journal Line for Customer, Taking 1 for positive sign factor.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostGeneralJournalLine(
          VATPostingSetup, GenJournalLine."Account Type"::Customer, Customer."No.", GenJournalLine."Gen. Posting Type"::Sale, 1, true);

        // Save VAT Statement Report for Sale with Open Selection and Verify the Amount. Passing FALSE to find Open Entries for Sale.
        // Exercise And Verification done in VATStatementForDifferentEntries function.
        VATStatementForDifferentEntries(VATPostingSetup, GenJournalLine."Gen. Posting Type"::Sale, Selection::Open, false);
    end;

    [Test]
    [HandlerFunctions('RHVATStatement')]
    [Scope('OnPrem')]
    procedure VATStatementWithClosedEntriesPurchase()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        Selection: Enum "VAT Statement Report Selection";
    begin
        // Test VAT Statement Report for Purchase with Closed VAT Entries.

        // Setup: Save VAT Statement Report with Closed Selection and Verify the Amount. Passing TRUE to find Close Entries.
        Initialize();
        FindVATPostingSetupFromVATEntries(VATPostingSetup, VATEntry.Type::Purchase);

        // Exercise And Verification done in VATStatementForDifferentEntries function.
        VATStatementForDifferentEntries(VATPostingSetup, VATEntry.Type::Purchase, Selection::Closed, true);
    end;

    [Test]
    [HandlerFunctions('RHVATStatement')]
    [Scope('OnPrem')]
    procedure VATStatementWithClosedEntriesSales()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        Selection: Enum "VAT Statement Report Selection";
    begin
        // Test VAT Statement Report for Sales with Closed VAT Entries.

        // Setup: Save VAT Statement Report with Closed Selection and Verify the Amount. Passing TRUE to find Close Entries for Sale.
        Initialize();
        FindVATPostingSetupFromVATEntries(VATPostingSetup, VATEntry.Type::Sale);

        // Exercise And Verification done in VATStatementForDifferentEntries function.
        VATStatementForDifferentEntries(VATPostingSetup, VATEntry.Type::Sale, Selection::Closed, true);
    end;

    [Test]
    [HandlerFunctions('RHCalcAndPostVATSettlement')]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementPostingDateError()
    var
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
    begin
        // Test Error Message when Posting Date is not filled while running Calc. and Post VAT Settlement Report.

        // Setup: Set Parameters for Report having Starting Date, Ending Date, Posting Date, Document No. and Settlement Account No as Blank.
        Initialize();
        Clear(CalcAndPostVATSettlement);
        CalcAndPostVATSettlement.InitializeRequest(0D, 0D, 0D, '', '', false, false);

        // Exercise: Try to save Report with TEST Name.
        asserterror CalcAndPostVATSettlement.Run();

        // Verify: Verify that Posting Date not filled error appears.
        Assert.ExpectedError(StrSubstNo(PostingDateErr));
    end;

    [Test]
    [HandlerFunctions('RHCalcAndPostVATSettlement')]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementDocNoError()
    var
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
    begin
        // Test Error Message when Document No. is not filled while running Calc. and Post VAT Settlement Report.

        // Setup: Set Parameters for Report having Starting Date, Ending Date, Document No. and Settlement Account No. as Blank, take Posting Date as WORKDATE.
        Initialize();
        Clear(CalcAndPostVATSettlement);
        CalcAndPostVATSettlement.InitializeRequest(0D, 0D, WorkDate(), '', '', false, false);

        // Exercise: Try to save Report with TEST Name.
        asserterror CalcAndPostVATSettlement.Run();

        // Verify: Verify that Document No. not filled error appears.
        Assert.ExpectedError(StrSubstNo(DocumentNoErr));
    end;

    [Test]
    [HandlerFunctions('RHCalcAndPostVATSettlement')]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementAccountError()
    var
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
    begin
        // Test Error Message when Settlement Account is not filled while running Calc. and Post VAT Settlement Report.

        // Setup: Set Parameters for Report having Starting Date, Ending Date and Settlement Account No. as Blank, take Posting Date as WORKDATE and a Random Document No. value is not important.
        Initialize();
        Clear(CalcAndPostVATSettlement);
        CalcAndPostVATSettlement.InitializeRequest(0D, 0D, WorkDate(), Format(LibraryRandom.RandInt(100)), '', false, false);

        // Exercise: Try to save Report with TEST Name.
        asserterror CalcAndPostVATSettlement.Run();

        // Verify: Verify that Settement Account No. not filled error appears.
        Assert.ExpectedError(StrSubstNo(SettlementAccountErr));
    end;

    [Test]
    [HandlerFunctions('RHCalcAndPostVATSettlement')]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementSalesPostTrue()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test Calc. and Post VAT Settlement Report for Sales and when posting is TRUE.

        // Calculate and Post VAT Settlement for Customer with Post TRUE, taking 1 for positive sign factor.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CalcAndPostVATSettlementWithPostingOption(
          GenJournalLine."Account Type"::Customer, Customer."No.", GenJournalLine."Gen. Posting Type"::Sale, 1, true);
    end;

    [Test]
    [HandlerFunctions('RHCalcAndPostVATSettlement')]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementSalesPostFalse()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test Calc. and Post VAT Settlement Report for Sales and when posting is FALSE.

        // Calculate and Post VAT Settlement for Customer with Post FALSE, taking 1 for positive sign factor.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CalcAndPostVATSettlementWithPostingOption(
          GenJournalLine."Account Type"::Customer, Customer."No.", GenJournalLine."Gen. Posting Type"::Sale, 1, false);
    end;

    [Test]
    [HandlerFunctions('RHCalcAndPostVATSettlement')]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementPurchasePostTrue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // Test Calc. and Post VAT Settlement Report for Purchase and when posting is TRUE.

        // Calculate and Post VAT Settlement for Vendor with Post TRUE, taking -1 for negative sign factor.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CalcAndPostVATSettlementWithPostingOption(
          GenJournalLine."Account Type"::Vendor, Vendor."No.", GenJournalLine."Gen. Posting Type"::Purchase, -1, true);
    end;

    [Test]
    [HandlerFunctions('RHCalcAndPostVATSettlement')]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementPurchasePostFalse()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // Test Calc. and Post VAT Settlement Report for Purchase and when posting is FALSE.

        // Calculate and Post VAT Settlement for Vendor with Post FALSE, taking -1 for negative sign factor.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CalcAndPostVATSettlementWithPostingOption(
          GenJournalLine."Account Type"::Vendor, Vendor."No.", GenJournalLine."Gen. Posting Type"::Purchase, -1, false);
    end;

    [Test]
    [HandlerFunctions('RHVATVIESDeclaration')]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationReport()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
        Item: Record Item;
    begin
        // Verify VAT VIES Declaration Tax Auth. Report.

        // Setup: Find Customer with VAT Registration Number, create and post four Sales Orders.
        Initialize();
        CreateCustomerWithCountryRegionVATRegNo(Customer);
        LibraryInventory.CreateItem(Item);
        PostSalesOrderWithVATSetup(Customer."No.", false, SalesLine.Type::Item, Item."No.");
        PostSalesOrderWithVATSetup(Customer."No.", true, SalesLine.Type::Item, Item."No.");

        LibraryERM.FindGLAccount(GLAccount);
        PostSalesOrderWithVATSetup(Customer."No.", false, SalesLine.Type::"G/L Account", GLAccount."No.");
        PostSalesOrderWithVATSetup(Customer."No.", true, SalesLine.Type::"G/L Account", GLAccount."No.");

        // Exercise: Save VAT VIES Declaration Tax Auth. Report.
        VATVIESDeclarationTaxReport(Customer."VAT Registration No.");

        // Verify: Verify Values on VAT VIES Declaration Tax Auth. Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('VATRegNo', Customer."VAT Registration No.");
        Assert.AreEqual(
          -CalculateBase(Customer."No.", 'Yes|No'), LibraryReportDataset.Sum('TotalValueofItemSupplies'),
          SameAmountErr);
        Assert.AreEqual(
          -CalculateBase(Customer."No.", 'Yes'), LibraryReportDataset.Sum('EU3PartyItemTradeAmt'),
          SameAmountErr);
    end;

    [Test]
    [HandlerFunctions('RHCalcAndPostVATSettlement')]
    [Scope('OnPrem')]
    procedure CalculateVATSettlementAfterPostSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Test Calc. and Post VAT Settlement Report for Sales with blank VAT Bus. Posting Group.

        // Setup: Create and Post Sales Order.
        Initialize();
        CreateVATPostingSetupWithBlankVATBusPostingGroup(VATPostingSetup);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(VATPostingSetup));
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Calculate and Post VAT Settlement for Customer.
        SaveCalcAndPostVATSettlementReport(VATPostingSetup, LibraryUtility.GenerateGUID, false); // Set False for Post.

        // Verify: Verify Values on Cal.And Post VAT Settlement Report.
        VerifyValuesOnCalcAndPostVATSettlementReport(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('RHCalcAndPostVATSettlement')]
    [Scope('OnPrem')]
    procedure CalculateVATSettlementAfterPostPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        DocumentNo: Code[20];
        OldReverseChargeVATPostingGroup: Code[20];
    begin
        // Test Calc. and Post VAT Settlement Report for Purchase with blank VAT Bus. Posting Group.

        // Setup: Create and Post Purchase Order.
        Initialize();
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);
        UpdateReverseChargeVATPostingGroup(OldReverseChargeVATPostingGroup, VATBusinessPostingGroup.Code);
        CreateVATPostingSetupWithBlankVATBusPostingGroup(VATPostingSetup);
        CreatePurchaseOrder(PurchaseHeader, VATPostingSetup);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Calculate and Post VAT Settlement for Vendor.
        SaveCalcAndPostVATSettlementReport(VATPostingSetup, LibraryUtility.GenerateGUID, false); // Set False for Post.

        // Verify: Verify Values on Cal.And Post VAT Settlement Report.
        VerifyValuesOnCalcAndPostVATSettlementReport(DocumentNo);

        // Tear down:Roll back field "Reverse Charge VAT Posting Gr." on Purchase and Payable setup
        UpdateReverseChargeVATPostingGroup(OldReverseChargeVATPostingGroup, OldReverseChargeVATPostingGroup);
    end;

    [Test]
    [HandlerFunctions('PurchaseReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckCompanyNameInPurchaseReceiptReport()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        CompanyInformation: Record "Company Information";
        DocumentNo: Code[20];
    begin
        // Verify that Purchase Receipt Report displaying Company Name.

        // Setup: Create purchase order
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchaseOrder(PurchaseHeader, VATPostingSetup);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchRcptHeader.SetRange("No.", DocumentNo);
        CompanyInformation.Get();

        // Exercise: Run Purchase - Receipt report.
        REPORT.Run(REPORT::"Purchase - Receipt", true, false, PurchRcptHeader);

        // Verify: Verifying company name is not blank on record and report.
        CompanyInformation.TestField(Name);
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('CompanyAddr1', CompanyInformation.Name);
    end;

    [Test]
    [HandlerFunctions('VATStatementTemplateListModalPageHandler,VATStatementExcelRPH')]
    [Scope('OnPrem')]
    procedure TestReportPrint_PrintVATStmtName()
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        VATStatementLine: array[2] of Record "VAT Statement Line";
        VATStatementTemplate: Record "VAT Statement Template";
        FileManagement: Codeunit "File Management";
        VATStatementNames: TestPage "VAT Statement Names";
        FileName: Text;
    begin
        // [FEATURE] [Report] [VAT Statement] [UI]
        // [SCENARIO 338378] "VAT Statement" report prints single page when the single vat statement line is reported from VAT Statement Names page
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostGeneralJournalLine(
          VATPostingSetup, GenJournalLine."Account Type"::Customer, Customer."No.", GenJournalLine."Gen. Posting Type"::Sale, 1, true);

        CreateVATStatementTemplateAndLine(VATStatementLine[1], VATPostingSetup, GenJournalLine."Gen. Posting Type"::Sale);
        CreateVATStatementTemplateAndLine(VATStatementLine[2], VATPostingSetup, GenJournalLine."Gen. Posting Type"::Sale);

        FileName := FileManagement.ServerTempFileName('xlsx');
        LibraryVariableStorage.Enqueue(VATStatementLine[1]."Statement Template Name");
        LibraryVariableStorage.Enqueue(FileName);

        Commit;

        VATStatementNames.OpenView;
        Commit();
        VATStatementNames."&Print".Invoke; // Print
        VATStatementNames.Close();

        Assert.AreEqual(1, LibraryReportValidation.CountWorksheets, TooManyWorksheetsErr);

        VATStatementTemplate.Get(VATStatementLine[1]."Statement Template Name");
        VATStatementTemplate.Delete(true);

        VATStatementTemplate.Get(VATStatementLine[2]."Statement Template Name");
        VATStatementTemplate.Delete(true);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('VATStatementTemplateListModalPageHandler,VATStatementExcelRPH')]
    [Scope('OnPrem')]
    procedure TestReportPrint_PrintVATStmtLine()
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        VATStatementLine: array[2] of Record "VAT Statement Line";
        VATStatementTemplate: Record "VAT Statement Template";
        FileManagement: Codeunit "File Management";
        VATStatement: TestPage "VAT Statement";
        FileName: Text;
    begin
        // [FEATURE] [Report] [VAT Statement] [UI]
        // [SCENARIO 338378] "VAT Statement" report prints single page when the single vat statement line is reported from VAT Statement card page
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostGeneralJournalLine(
          VATPostingSetup, GenJournalLine."Account Type"::Customer, Customer."No.", GenJournalLine."Gen. Posting Type"::Sale, 1, true);

        CreateVATStatementTemplateAndLine(VATStatementLine[1], VATPostingSetup, GenJournalLine."Gen. Posting Type"::Sale);
        CreateVATStatementTemplateAndLine(VATStatementLine[2], VATPostingSetup, GenJournalLine."Gen. Posting Type"::Sale);

        FileName := FileManagement.ServerTempFileName('xlsx');
        LibraryVariableStorage.Enqueue(VATStatementLine[1]."Statement Template Name");
        LibraryVariableStorage.Enqueue(FileName);

        Commit;

        VATStatement.OpenView;
        VATStatement.Print.Invoke;
        VATStatement.Close();

        Assert.AreEqual(1, LibraryReportValidation.CountWorksheets, TooManyWorksheetsErr);

        VATStatementTemplate.Get(VATStatementLine[1]."Statement Template Name");
        VATStatementTemplate.Delete(true);

        VATStatementTemplate.Get(VATStatementLine[2]."Statement Template Name");
        VATStatementTemplate.Delete(true);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('GLVATReconciliationRequestPageHandler,ConfirmHandlerWithVariable')]
    [Scope('OnPrem')]
    procedure PrintGLVATReconciliationSameRowNoConfirmYesOnce()
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
        GenJournalLine: Record "Gen. Journal Line";
        VATStatementLine: array[2] of Record "VAT Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
        RequestPageXML: Text;
    begin
        // [FEATURE] [Report] [G/L VAT Reconciliation]
        // [SCENARIO 416991] "G/L VAT Reconciliation" report prints VAT Statement Lines with same "Row No.", "VAT Bus./Prod" groups, but different Gen. Posting Type
        Initialize();

        // [GIVEN] VAT Statement "V"
        CreateVATPostingSetupWithBlankVATBusPostingGroup(VATPostingSetup);
        CreateVATStatementTemplateAndName(VATStatementTemplate, VATStatementName);

        // [GIVEN] VAT Statement line 1 with "Row No." = "AAA" and "General Posting Type" = Sale
        CreateVATStatementLine(VATStatementLine[1], VATStatementTemplate, VATStatementName, VATPostingSetup, "General Posting Type"::Sale);
        VATStatementLine[1]."Row No." := 'AAA';
        VATStatementLine[1].Description := 'Sale';
        VATStatementLine[1].Modify();
        CreateAndPostGeneralJournalLine(
            VATPostingSetup, GenJournalLine."Account Type"::Customer, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"),
            GenJournalLine."Gen. Posting Type"::Sale, 1, false);

        // [GIVEN] VAT Statement line 2 with "Row No." = "AAA" and "General Posting Type" = Purchase
        CreateVATStatementLine(VATStatementLine[2], VATStatementTemplate, VATStatementName, VATPostingSetup, "General Posting Type"::Purchase);
        VATStatementLine[2]."Row No." := 'AAA';
        VATStatementLine[2].Description := 'Purchase';
        VATStatementLine[2].Modify();
        CreateAndPostGeneralJournalLine(
            VATPostingSetup, GenJournalLine."Account Type"::Vendor, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"),
            GenJournalLine."Gen. Posting Type"::Purchase, -1, false);

        // [WHEN] Print report "G/L VAT Reconciliation" for VAT Statement "V"
        // Bug 429182: the only single confirmation request required when customer responds "Yes" to request for VAT Entry table adjustment
        LibraryVariableStorage.Enqueue(true);
        Commit();
        RequestPageXML := Report.RunRequestPage(Report::"G/L - VAT Reconciliation", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"G/L - VAT Reconciliation", VATStatementName, RequestPageXML);

        // [THEN] Both lines Sale and Purchase are printed
        LibraryReportDataset.AssertElementWithValueExists('VAT_Statement_Line_Description', VATStatementLine[1].Description);
        LibraryReportDataset.AssertElementWithValueExists('VAT_Statement_Line_Description', VATStatementLine[2].Description);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GLVATReconciliationRequestPageHandler,ConfirmHandlerWithVariable')]
    [Scope('OnPrem')]
    procedure PrintGLVATReconciliationSameRowNoConfirmNoOnce()
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
        GenJournalLine: Record "Gen. Journal Line";
        VATStatementLine: array[2] of Record "VAT Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
        RequestPageXML: Text;
    begin
        // [FEATURE] [Report] [G/L VAT Reconciliation]
        // [SCENARIO 416991] "G/L VAT Reconciliation" report prints VAT Statement Lines with same "Row No.", "VAT Bus./Prod" groups, but different Gen. Posting Type
        Initialize();

        // [GIVEN] VAT Statement "V"
        CreateVATPostingSetupWithBlankVATBusPostingGroup(VATPostingSetup);
        CreateVATStatementTemplateAndName(VATStatementTemplate, VATStatementName);

        // [GIVEN] VAT Statement line 1 with "Row No." = "AAA" and "General Posting Type" = Sale
        CreateVATStatementLine(VATStatementLine[1], VATStatementTemplate, VATStatementName, VATPostingSetup, "General Posting Type"::Sale);
        VATStatementLine[1]."Row No." := 'AAA';
        VATStatementLine[1].Description := 'Sale';
        VATStatementLine[1].Modify();
        CreateAndPostGeneralJournalLine(
            VATPostingSetup, GenJournalLine."Account Type"::Customer, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"),
            GenJournalLine."Gen. Posting Type"::Sale, 1, false);

        // [GIVEN] VAT Statement line 2 with "Row No." = "AAA" and "General Posting Type" = Purchase
        CreateVATStatementLine(VATStatementLine[2], VATStatementTemplate, VATStatementName, VATPostingSetup, "General Posting Type"::Purchase);
        VATStatementLine[2]."Row No." := 'AAA';
        VATStatementLine[2].Description := 'Purchase';
        VATStatementLine[2].Modify();
        CreateAndPostGeneralJournalLine(
            VATPostingSetup, GenJournalLine."Account Type"::Vendor, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"),
            GenJournalLine."Gen. Posting Type"::Purchase, -1, false);

        // [WHEN] Print report "G/L VAT Reconciliation" for VAT Statement "V"
        // Bug 429182: the only single confirmation request required when customer responds "No" to request for VAT Entry table adjustment
        LibraryVariableStorage.Enqueue(false);
        Commit();
        RequestPageXML := Report.RunRequestPage(Report::"G/L - VAT Reconciliation", RequestPageXML);
        asserterror LibraryReportDataset.RunReportAndLoad(Report::"G/L - VAT Reconciliation", VATStatementName, RequestPageXML);

        // [THEN] Both lines Sale and Purchase are printed
        Assert.ExpectedError(VATGLAccountErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('GLVATReconciliationWithDateFilterRequestPageHandler,ConfirmHandlerWithVariable')]
    [Scope('OnPrem')]
    procedure PrintGLVATReconciliationWithinDateRange()
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
        GenJournalLine: Record "Gen. Journal Line";
        VATStatementLine: array[2] of Record "VAT Statement Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        CustomerNo: Code[20];
        VendorNo: Code[20];
        RequestPageXML: Text;
    begin
        // [FEATURE] [Report] [G/L VAT Reconciliation]
        // [SCENARIO 436837] "G/L VAT Reconciliation" report doesn't adjust VAT Entries that are filtered out by user's setup on request page
        Initialize();

        // [GIVEN] VAT Statement "V"
        CreateVATPostingSetupWithBlankVATBusPostingGroup(VATPostingSetup);
        CreateVATStatementTemplateAndName(VATStatementTemplate, VATStatementName);

        // [GIVEN] VAT Statement line 1 with "Row No." = "AAA" and "General Posting Type" = Sale
        CreateVATStatementLine(VATStatementLine[1], VATStatementTemplate, VATStatementName, VATPostingSetup, "General Posting Type"::Sale);
        VATStatementLine[1]."Row No." := 'AAA';
        VATStatementLine[1].Description := 'Sale';
        VATStatementLine[1].Modify();
        // [GIVEN] Document posted for Customer "A" at Posting Date = "01 Jan 2020"
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        CreateAndPostGeneralJournalLine(
            VATPostingSetup, GenJournalLine."Account Type"::Customer, CustomerNo, GenJournalLine."Gen. Posting Type"::Sale, 1, false);

        // [GIVEN] VAT Statement line 2 with "Row No." = "AAA" and "General Posting Type" = Purchase
        CreateVATStatementLine(VATStatementLine[2], VATStatementTemplate, VATStatementName, VATPostingSetup, "General Posting Type"::Purchase);
        VATStatementLine[2]."Row No." := 'AAA';
        VATStatementLine[2].Description := 'Purchase';
        VATStatementLine[2].Modify();
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group");
        // [GIVEN] Document posted for Vendor "B" at Posting Date = "31 Dec 2019"
        CreateAndPostGeneralJournalLine(
            VATPostingSetup, WorkDate() - 1, GenJournalLine."Account Type"::Vendor, VendorNo, GenJournalLine."Gen. Posting Type"::Purchase, -1, false);

        // [WHEN] Print report "G/L VAT Reconciliation" for VAT Statement "V" with date range = "1 Jan 2020"
        LibraryVariableStorage.Enqueue(PeriodSelection::"Within Period");
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(true);
        Commit();
        RequestPageXML := Report.RunRequestPage(Report::"G/L - VAT Reconciliation", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"G/L - VAT Reconciliation", VATStatementName, RequestPageXML);

        // [THEN] Line Sale is printed and Purchase are printed
        LibraryReportDataset.AssertElementWithValueExists('VAT_Statement_Line_Description', VATStatementLine[1].Description);
        // [THEN] Line Purchase is not printed
        LibraryReportDataset.AssertElementWithValueNotExist('VAT_Statement_Line_Description', VATStatementLine[2].Description);

        // [THEN] Sales VAT Entry is adjusted
        VATEntry.SetRange("VAT Bus. Posting Group", VATStatementLine[1]."VAT Bus. Posting Group");
        VATEntry.SetRange("Bill-to/Pay-to No.", CustomerNo);
        VATEntry.FindFirst();
        VATEntry.TestField("G/L Acc. No.");

        // [THEN] Purchase VAT Entry is not adjusted
        VATEntry.SetRange("VAT Bus. Posting Group", VATStatementLine[2]."VAT Bus. Posting Group");
        VATEntry.SetRange("Bill-to/Pay-to No.", VendorNo);
        VATEntry.FindFirst();
        VATEntry.TestField("G/L Acc. No.", '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATStatementTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyVATDateUsedOnVATStatementReport()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATReportingDate: Date;
        PostingDate: Date;
        GLAccountNoFrom: Code[20];
        GLAccountNoTo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Report] [VAT Statement] Test VAT Statement Report is using VAT Reporting Date as Date filter 
        // [GIVEN] Posted a general journal line with different Posting and VAT Reporting Date       
        Initialize();

        PostingDate := CalcDate('<+2M>', GetLastPostingDate());
        VATReportingDate := CalcDate('<+1M>', PostingDate);

        CreateVATPostingSetup(VATPostingSetup);

        GLAccountNoFrom := LibraryERM.CreateGLAccountNoWithDirectPosting();
        GLAccountNoTo := CreateGLAccountWithVAT(VATPostingSetup);

        // [WHEN] Generla Journal Line with different Posting and VAT Registraion Date is posted 
        PostGenJournalLine(GLAccountNoFrom, GLAccountNoTo, Amount, PostingDate, VATReportingDate);

        // [THEN] VAT Statement conatins VAT Statement Line if report run in VAT Resitsration Date period
        VerifyVATStatementWithinSelectedPeriod(VATPostingSetup, GLAccountNoTo, VATReportingDate);

    end;

    local procedure Initialize()
    var
        ObjectOptions: Record "Object Options";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Financial Reports IV");
        LibraryVariableStorage.Clear();
        Clear(LibraryReportValidation);

        ObjectOptions.SetRange("Object Type", ObjectOptions."Object Type"::Report);
        ObjectOptions.SetRange("Object ID", REPORT::"VAT Statement");
        ObjectOptions.DeleteAll();
        Commit();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Financial Reports IV");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Financial Reports IV");
    end;

    local procedure FindVATPostingSetupFromVATEntries(var VATPostingSetup: Record "VAT Posting Setup"; EntryType: Enum "Tax Calculation Type")
    var
        VATEntry: Record "VAT Entry";
    begin
        with VATEntry do begin
            SetRange("VAT Calculation Type", "VAT Calculation Type"::"Normal VAT");
            SetRange(Type, EntryType);
            SetRange(Closed, Closed);
            FindFirst();
            VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
        end;
    end;

    local procedure CalcAndPostVATSettlementWithPostingOption(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20];
                                                                               GenPostingType: Enum "General Posting Type";
                                                                               SignFactor: Integer;
                                                                               Post: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        Amount: Decimal;
    begin
        // Setup: Create and Post General Journal Line with different Account Types, Find VAT Entries Amount.
        CreateAndPostGeneralJournalLine(VATPostingSetup, AccountType, AccountNo, GenPostingType, SignFactor, true);
        VATEntry.SetRange("Posting Date", WorkDate());
        Amount := -CalculateVATEntryAmount(VATEntry, VATPostingSetup, GenPostingType, false);

        // Exercise: Taking Random No. for Document No., value is not important.
        SaveCalcAndPostVATSettlementReport(VATPostingSetup, Format(LibraryRandom.RandInt(100)), Post);

        // Verify: Verify Amount on Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('GenJnlLineVATAmount', Amount);
    end;

    local procedure CalculateVATEntryAmount(var VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; Type: Enum "Tax Calculation Type"; Closed: Boolean) TotalAmount: Decimal
    begin
        VATEntry.SetRange(Type, Type);
        VATEntry.SetRange(Closed, Closed);
        VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATEntry.CalcSums(Amount);
        TotalAmount := VATEntry.Amount;
    end;

    local procedure CreateAndPostGeneralJournalLine(var VATPostingSetup: Record "VAT Posting Setup"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20];
                                                                                                                      GenPostingType: Enum "General Posting Type";
                                                                                                                      SignFactor: Integer;
                                                                                                                      FindVATPostingSetup: Boolean)
    begin
        CreateAndPostGeneralJournalLine(VATPostingSetup, WorkDate(), AccountType, AccountNo, GenPostingType, SignFactor, FindVATPostingSetup);
    end;

    local procedure CreateAndPostGeneralJournalLine(var VATPostingSetup: Record "VAT Posting Setup"; PostingDate: Date; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20];
                                                                                                                                         GenPostingType: Enum "General Posting Type";
                                                                                                                                         SignFactor: Integer;
                                                                                                                                         FindVATPostingSetup: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        if FindVATPostingSetup then
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          AccountType, AccountNo, SignFactor * LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account No.", CreateGLAccountWithVAT(VATPostingSetup, GenPostingType));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCustomerWithCountryRegionVATRegNo(var Customer: Record Customer)
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("EU Country/Region Code", CountryRegion.Code);
        CountryRegion.Modify(true);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code);
        Customer.Modify(true);
    end;

    local procedure CreateGLAccountWithVAT(VATPostingSetup: Record "VAT Posting Setup"; GenPostingType: Enum "General Posting Type"): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GenPostingType);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateVATStatementTemplateAndLine(var VATStatementLine: Record "VAT Statement Line"; VATPostingSetup: Record "VAT Posting Setup"; GenPostingType: Enum "General Posting Type")
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementName: Record "VAT Statement Name";
    begin
        CreateVATStatementTemplateAndName(VATStatementTemplate, VATStatementName);
        CreateVATStatementLine(VATStatementLine, VATStatementTemplate, VATStatementName, VATPostingSetup, GenPostingType);
    end;

    local procedure CreateVATStatementTemplateAndName(var VATStatementTemplate: Record "VAT Statement Template"; var VATStatementName: Record "VAT Statement Name")
    begin
        LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
        VATStatementTemplate.Validate("VAT Statement Report ID", REPORT::"VAT Statement");
        VATStatementTemplate.Modify(true);
        LibraryERM.CreateVATStatementName(VATStatementName, VATStatementTemplate.Name);
    end;

    local procedure CreateVATStatementLine(var VATStatementLine: Record "VAT Statement Line"; VATStatementTemplate: Record "VAT Statement Template"; VATStatementName: Record "VAT Statement Name"; VATPostingSetup: Record "VAT Posting Setup"; GenPostingType: Enum "General Posting Type")
    begin
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementTemplate.Name, VATStatementName.Name);
        VATStatementLine.Validate("Row No.", Format(LibraryRandom.RandInt(100)));
        VATStatementLine.Validate(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.Validate("Gen. Posting Type", GenPostingType);
        VATStatementLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATStatementLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATStatementLine.Validate("Amount Type", VATStatementLine."Amount Type"::Amount);
        VATStatementLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(VATPostingSetup));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATPostingSetup), LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CalculateBase(CustomerNo: Code[20]; EU3PartyTrade: Text[10]) TotalBase: Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetFilter("EU 3-Party Trade", EU3PartyTrade);
        FindVATEntry(VATEntry, CustomerNo);
        repeat
            TotalBase += VATEntry.Base;
        until VATEntry.Next() = 0;
    end;

    local procedure CreateCustomer(var VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(var VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20])
    begin
        // Create Sales Document with Random Quantity and Unit Price.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, LibraryRandom.RandDec(100, 2) * 100);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateVendor(var VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVATPostingSetupWithBlankVATBusPostingGroup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, '', VATProductPostingGroup.Code); // Set VAT Bus. Posting Group to blank.
        VATPostingSetup.Validate("VAT Identifier", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(10));
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateCustomer(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        with Customer do begin
            Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure CreateVendor(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        with Vendor do begin
            Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; BilltoPaytoNo: Code[20])
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", BilltoPaytoNo);
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.SetRange("Posting Date", WorkDate());
        VATEntry.FindSet();
    end;

    local procedure PostSalesOrderWithVATSetup(CustomerNo: Code[20]; EU3PartyTrade: Boolean; Type: Enum "Sales Line Type"; No: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("EU 3-Party Trade", EU3PartyTrade);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, Type, No);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure SaveCalcAndPostVATSettlementReport(VATPostingSetup: Record "VAT Posting Setup"; DocumentNo: Code[20]; Post: Boolean)
    var
        GLAccount: Record "G/L Account";
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        Clear(CalcAndPostVATSettlement);
        VATPostingSetup.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        CalcAndPostVATSettlement.SetTableView(VATPostingSetup);
        CalcAndPostVATSettlement.InitializeRequest(WorkDate(), WorkDate(), WorkDate, DocumentNo, GLAccount."No.", false, Post);
        Commit();
        CalcAndPostVATSettlement.Run();
    end;

    local procedure SaveVATStatementReport(Name: Code[10]; Selection: Enum "VAT Statement Report Selection"; PeriodSelection: Enum "VAT Statement Report Period Selection")
    var
        VATStatementLine: Record "VAT Statement Line";
        VATStatementName: Record "VAT Statement Name";
        VATStatement: Report "VAT Statement";
    begin
        Clear(VATStatement);
        VATStatementName.SetRange(Name, Name);
        VATStatement.SetTableView(VATStatementName);
        VATStatement.InitializeRequest(VATStatementName, VATStatementLine, Selection, PeriodSelection, false, false);
        Commit();
        VATStatement.Run();
    end;

    local procedure UpdateReverseChargeVATPostingGroup(var OldReverseChargeVATPostingGroup: Code[20]; ReverseChargeVATPostingGroup: Code[20])
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        OldReverseChargeVATPostingGroup := PurchasesPayablesSetup."Reverse Charge VAT Posting Gr.";
        PurchasesPayablesSetup.Validate("Reverse Charge VAT Posting Gr.", ReverseChargeVATPostingGroup);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure VATStatementForDifferentEntries(VATPostingSetup: Record "VAT Posting Setup"; EntryType: Enum "Tax Calculation Type"; Selection: Enum "VAT Statement Report Selection"; Closed: Boolean)
    var
        VATStatementLine: Record "VAT Statement Line";
        VATStatementTemplate: Record "VAT Statement Template";
        VATEntry: Record "VAT Entry";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        Amount: Decimal;
    begin
        // Calculate VAT Entry Amount according to entry type, Create VAT Statement Template and VAT Statement Line.
        Amount := CalculateVATEntryAmount(VATEntry, VATPostingSetup, EntryType, Closed);
        CreateVATStatementTemplateAndLine(VATStatementLine, VATPostingSetup, EntryType);

        // Exercise.
        SaveVATStatementReport(VATStatementLine."Statement Name", Selection, PeriodSelection::"Within Period");

        // Verify: Verify Amount on VAT Statement Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('VatStmtLineRowNo', VATStatementLine."Row No.");
        if not LibraryReportDataset.GetNextRow then
            Error(NoDataRowErr, 'VatStmtLineRowNo', VATStatementLine."Row No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalAmount', Amount);

        // Tear Down: Delete VAT Statement Template created earlier.
        VATStatementTemplate.Get(VATStatementLine."Statement Template Name");
        VATStatementTemplate.Delete(true);
    end;

    local procedure VATVIESDeclarationTaxReport(CustomerVATRegistrationNo: Text[20])
    var
        VATVIESDeclarationTaxAuth: Report "VAT- VIES Declaration Tax Auth";
    begin
        Clear(VATVIESDeclarationTaxAuth);
        VATVIESDeclarationTaxAuth.InitializeRequest(false, WorkDate(), WorkDate, CustomerVATRegistrationNo);
        VATVIESDeclarationTaxAuth.Run();
    end;

    local procedure VerifyValuesOnCalcAndPostVATSettlementReport(DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        LibraryReportDataset.LoadDataSetFile;
        Assert.AreEqual(
          LibraryReportDataset.Sum('GenJnlLineVATBaseAmount'), -VATEntry.Base,
          SameAmountErr);

        Assert.AreEqual(
          LibraryReportDataset.Sum('GenJnlLineVATAmount'), -VATEntry.Amount,
          SameAmountErr);
    end;

    local procedure GetLastPostingDate(): Date
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey("Posting Date");
        VATEntry.FindLast();
        exit(VATEntry."Posting Date");
    end;

    local procedure PostGenJournalLine(GLAccountNoFrom: Code[20]; GLAccountNoTo: Code[20]; var Amount: Decimal; PostingDate: Date; VATReportingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalAccountType: Enum "Gen. Journal Account Type";
        GenJournalDocumentType: Enum "Gen. Journal Document Type";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        Amount := LibraryRandom.RandDec(100, 2);
        LibraryERM.CreateGeneralJnlLine2WithBalAcc(GenJournalLine,
            GenJournalTemplate.Name,
            GenJournalBatch.Name,
            GenJournalDocumentType::" ",
            GenJournalAccountType::"G/L Account",
            GLAccountNoFrom,
            GenJournalAccountType::"G/L Account",
            GLAccountNoTo,
            Amount);

        GenJournalLine."Posting Date" := PostingDate;
        GenJournalLine."VAT Reporting Date" := VATReportingDate;
        GenJournalLine."Bal. Gen. Posting Type" := GenJournalLine."Bal. Gen. Posting Type"::"Sale";
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup."Sales VAT Account" := GLAccount."No.";
        VATPostingSetup."VAT %" := LibraryRandom.RandInt(20);
        VATPostingSetup.Modify();
    end;

    local procedure CreateGLAccountWithVAT(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GenPostingType: Enum "General Posting Type";
    begin
        exit(CreateGLAccountWithVAT(VATPostingSetup, GenPostingType::"Sale"));
    end;

    local procedure VerifyVATStatementWithinSelectedPeriod(VATPostingSetup: Record "VAT Posting Setup"; GLAccountTotalingNo: Code[20]; VATReportingDate: Date)
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        VATStatementPreview: TestPage "VAT Statement Preview";
        VATStatement: TestPage "VAT Statement";
        TotalAmount: Decimal;
    begin
        // Create VAT Statement Name and VAT Statement Line
        LibraryERM.CreateVATStatementNameWithTemplate(VATStatementName);
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name);
        VATStatementLine.Validate(Type, VATStatementLine.Type::"Account Totaling");
        VATStatementLine.Validate("Account Totaling", GLAccountTotalingNo);
        VATStatementLine.Validate("Calculate with", VATStatementLine."Calculate with"::"Opposite Sign");
        VATStatementLine.Modify(true);
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");

        // Open page "VAT Statement Preview" for created line
        VATStatement.OpenEdit();
        VATStatement.Filter.SetFilter("Statement Template Name", VATStatementLine."Statement Template Name");
        VATStatement.Filter.SetFilter("Statement Name", VATStatementLine."Statement Name");
        VATStatement.First();
        VATStatementPreview.Trap();
        VATStatement."P&review".Invoke();

        // Find related VAT Entry to get amount
        VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATEntry.SetRange("VAT Reporting Date", VATReportingDate);
        VatEntry.FindFirst();

        VATEntry.CalcSums(Base);
        TotalAmount := -VATEntry.Base;

        // Open VAT Statement Preview with Date Filter within VAT Reporting Date and verify amount
        VATStatementPreview.PeriodSelection.SetValue('Within Period');
        VATStatementPreview.DateFilter.SetValue(Format(VATReportingDate) + '..' + Format(VATReportingDate));
        Assert.AreEqual(TotalAmount, VATStatementPreview.VATStatementLineSubForm.ColumnValue.AsDecimal(), '');
        VATStatementPreview.Close();

        // Open VAT Statement Preview with Date Filter within Posting Date to verify that amount is 0 as entry is out of date filter
        VATStatementPreview.Trap();
        VATStatement."P&review".Invoke();
        VATStatementPreview.PeriodSelection.SetValue('Within Period');
        VATStatementPreview.DateFilter.SetValue(Format(VATEntry."Posting Date") + '..' + Format(VATEntry."Posting Date"));
        Assert.AreEqual(0, VATStatementPreview.VATStatementLineSubForm.ColumnValue.AsDecimal(), '');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVATStatement(var VATStatement: TestRequestPage "VAT Statement")
    begin
        VATStatement.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName)
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCalcAndPostVATSettlement(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    begin
        if CalcAndPostVATSettlement.Editable then;
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName)
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVATVIESDeclaration(var VATVIESDeclaration: TestRequestPage "VAT- VIES Declaration Tax Auth")
    begin
        VATVIESDeclaration.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName)
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseReceiptRequestPageHandler(var PurchaseReceipt: TestRequestPage "Purchase - Receipt")
    begin
        PurchaseReceipt.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATStatementTemplateListModalPageHandler(var VATStatementTemplateList: TestPage "VAT Statement Template List")
    begin
        VATStatementTemplateList.FILTER.SetFilter(Name, LibraryVariableStorage.DequeueText);
        VATStatementTemplateList.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStatementExcelRPH(var VATStatement: TestRequestPage "VAT Statement")
    var
        FileName: Text;
    begin
        FileName := LibraryVariableStorage.DequeueText;
        LibraryReportValidation.SetFileName(FileName);
        LibraryReportValidation.SetFullFileName(FileName);
        VATStatement.SaveAsExcel(LibraryReportValidation.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLVATReconciliationRequestPageHandler(var GLVATReconciliation: TestRequestPage "G/L - VAT Reconciliation")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLVATReconciliationWithDateFilterRequestPageHandler(var GLVATReconciliation: TestRequestPage "G/L - VAT Reconciliation")
    begin
        GLVATReconciliation.PeriodSelection.SetValue(LibraryVariableStorage.DequeueInteger());
        GLVATReconciliation.StartDate.SetValue(LibraryVariableStorage.DequeueDate());
        GLVATReconciliation.EndDateReq.SetValue(LibraryVariableStorage.DequeueDate());
        GLVATReconciliation.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerWithVariable(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}

