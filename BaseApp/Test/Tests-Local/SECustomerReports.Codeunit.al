codeunit 144026 "SE Customer Reports"
{
    // 1. Check Total equal to Customer Balance(LCY) exist on Customer Statement Report.
    // 2. Check G/L Account value does not exist on Balance Sheet Report.
    // 3. Check G/L Account value does exists on Balance Sheet Report when ShowAll is set to true
    // 4. Check G/L Account value does not exist on Income Statement Report.
    // 
    //  Bug = 305521
    //  Covers Test cases:
    //  ----------------------------------------------------------------
    //  Test Function Name                                       TFS ID
    //  ----------------------------------------------------------------
    //  CheckTotalOnCustomerStatementReport                      303235
    // 
    //  Bug = 46296
    //  Covers Test cases:
    //   ----------------------------------------------------------------
    //  Test Function Name                                       TFS ID
    //  ----------------------------------------------------------------
    //  CheckValueOnBalanceSheetReport
    //  CheckValueOnIncomeStatementReport
    // 
    //  Bug = 71047
    //  Covers Test cases:
    //   ----------------------------------------------------------------
    //  Test Function Name                                       TFS ID
    //  ----------------------------------------------------------------
    //  CheckValueOnBalanceSheetReportPrintAll

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        BalanceReportErr: Label 'Balance(LCY) %1 must exist in the Report', Comment = '.';
#if not CLEAN23
        ValueNotExistErr: Label 'Value must not exist.';
        ValueMustExistErr: Label 'Value must exist.';
#endif

    [Test]
    [Scope('OnPrem')]
    procedure CheckTotalOnCustomerStatementReport()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        "Count": Integer;
    begin
        // Check Total equal to Customer Balance(LCY) exist on Customer Statement Report.

        // Setup: Create and Post Sales Orders for same Customer.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        for Count := 1 to LibraryRandom.RandIntInRange(2, 4) do
            CreateAndPostSalesOrder(SalesHeader, Customer."No.");

        // Exercise: Save Customer Statement Report.
        SaveCustomerStatement(Customer."No.");

        // Verify: Verify Customer.Balance(LCY) exists in Report.
        Customer.CalcFields("Balance (LCY)");
        LibraryReportValidation.OpenFile();
        Assert.IsTrue(
          LibraryReportValidation.CheckIfDecimalValueExists(Customer."Balance (LCY)"),
          StrSubstNo(BalanceReportErr, Customer."Balance (LCY)"));
    end;

#if not CLEAN23
    [Test]
    [Obsolete('SE Balance Sheet tests are moved to SE Core extension', '23.0')]
    [HandlerFunctions('BalanceSheetReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckValueOnBalanceSheetReport()
    var
        GLAccount: Record "G/L Account";
        PrintAll: Boolean;
    begin
        // Check G/L Account value does not exist on Balance Sheet Report.

        // Setup: Create and Post Sales Orders.
        Initialize();
        CreateGLAccount(GLAccount, GLAccount."Income/Balance"::"Balance Sheet");
        CreateAndPostSalesOrderwithGL(GLAccount."No.");

        // Exercise: Save Balance Sheet Report.
        PrintAll := false;
        LibraryVariableStorage.Enqueue(PrintAll);
        SaveBalanceSheetReport(GLAccount."No.");

        // Verify: Verify value does not exist on Report when balance brought forward and balance at date are zero.
        VerifyValueOnReport(GLAccount, false);
    end;

    [Test]
    [Obsolete('SE Balance Sheet tests are moved to SE Core extension', '23.0')]
    [HandlerFunctions('BalanceSheetReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckValueOnBalanceSheetReportPrintAll()
    var
        GLAccount: Record "G/L Account";
        PrintAll: Boolean;
    begin
        // Check G/L Account value does exist on Balance Sheet Report when print all is activated.

        // Setup: Create and Post Sales Orders.
        Initialize();
        CreateGLAccount(GLAccount, GLAccount."Income/Balance"::"Balance Sheet");
        CreateAndPostSalesOrderwithGL(GLAccount."No.");

        // Exercise: Save Balance Sheet Report.
        PrintAll := true;
        LibraryVariableStorage.Enqueue(PrintAll);
        SaveBalanceSheetReport(GLAccount."No.");

        // Verify: Verify value does exist on Report even when balance brought forward and balance at date are zero.
        VerifyValueOnReport(GLAccount, true);

        GLAccount.Delete();
    end;

    [Test]
    [Obsolete('SE Income Statement tests are moved to SE Core extension', '23.0')]
    [Scope('OnPrem')]
    procedure CheckValueOnIncomeStatementReport()
    var
        GLAccount: Record "G/L Account";
    begin
        // Check G/L Account value does not exist on Income Statement Report.

        // Setup: Create and Post Sales Orders.
        Initialize();
        CreateGLAccount(GLAccount, GLAccount."Income/Balance"::"Income Statement");
        CreateAndPostSalesOrderwithGL(GLAccount."No.");

        // Exercise: Save Income Statement Report.
        SaveIncomeStatementReport(GLAccount."No.");

        // Verify: Verify record does not exist on Report when period balance is zero.
        VerifyValueOnReport(GLAccount, false);
    end;
#endif

    [Test]
    [HandlerFunctions('ReminderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReminderReportCompanyInfoVATRegistrationNoCaption()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [RDLC] [Reminder] [Report Layout]
        // [SCENARIO 337358] Report Reminder prints VAT Registration No. caption for company information section
        Initialize();

        // [GIVEN] Issued reminder 
        MockIssuedReminder(IssuedReminderHeader);

        // [WHEN] Reminder is being printed
        IssuedReminderHeader.SetRecFilter();
        Commit();
        REPORT.Run(REPORT::Reminder, true, false, IssuedReminderHeader);

        // [THEN] VAT Registration No. caption is printed in company information section
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CompanyVATRegistrationNoCaption', CompanyInformation.GetVATRegistrationNumberLbl());
    end;

    local procedure Initialize()
    var
        FeatureKey: Record "Feature Key";
        FeatureKeyUpdateStatus: Record "Feature Data Update Status";
    begin
        if FeatureKey.Get('ReminderTermsCommunicationTexts') then begin
            FeatureKey.Enabled := FeatureKey.Enabled::None;
            FeatureKey.Modify();
        end;
        if FeatureKeyUpdateStatus.Get('ReminderTermsCommunicationTexts', CompanyName()) then begin
            FeatureKeyUpdateStatus."Feature Status" := FeatureKeyUpdateStatus."Feature Status"::Disabled;
            FeatureKeyUpdateStatus.Modify();
        end;
        Clear(LibraryReportValidation);
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;

    local procedure MockIssuedReminder(var IssuedReminderHeader: Record "Issued Reminder Header")
    var
        IssuedReminderLine: Record "Issued Reminder Line";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        IssuedReminderHeader.Init();
        IssuedReminderHeader."No." :=
          LibraryUtility.GenerateRandomCode(IssuedReminderHeader.FieldNo("No."), DATABASE::"Issued Reminder Header");
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup."Additional Fee Account" := '';
        CustomerPostingGroup.Modify();
        IssuedReminderHeader."Customer Posting Group" := CustomerPostingGroup.Code;
        IssuedReminderHeader."Due Date" := LibraryRandom.RandDate(LibraryRandom.RandIntInRange(10, 100));
        IssuedReminderHeader.Insert();
        IssuedReminderLine.Init();
        IssuedReminderLine."Line No." := LibraryUtility.GetNewRecNo(IssuedReminderLine, IssuedReminderLine.FieldNo("Line No."));
        IssuedReminderLine."Line Type" := IssuedReminderLine."Line Type"::"Reminder Line";
        IssuedReminderLine."Reminder No." := IssuedReminderHeader."No.";
        IssuedReminderLine."Due Date" := IssuedReminderHeader."Due Date";
        IssuedReminderLine."Remaining Amount" := LibraryRandom.RandIntInRange(10, 100);
        IssuedReminderLine.Amount := IssuedReminderLine."Remaining Amount";
        IssuedReminderLine.Type := IssuedReminderLine.Type::"G/L Account";
        IssuedReminderLine.Insert();
    end;

    local procedure CreateAndPostSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

#if not CLEAN23
    local procedure CreateGLAccount(var GLAccount: Record "G/L Account"; GLAccountType: Option)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Validate("Income/Balance", GLAccountType);
        GLAccount.Modify(true);
    end;


    local procedure CreateAndPostSalesOrderwithGL(GLAccountNo: Code[20])
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit Price", 0);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure SaveBalanceSheetReport(GLAccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        BalanceSheet: Report "Balance sheet";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        Clear(BalanceSheet);
        GLAccount.SetRange("No.", GLAccountNo);
        GLAccount.SetFilter("Date Filter", '%1..%2', CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));
        BalanceSheet.SetTableView(GLAccount);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        Commit();
        BalanceSheet.Run();
    end;
#endif

    local procedure SaveCustomerStatement(CustomerNo: Code[20])
    var
        Customer: Record Customer;
        Statement: Report Statement;
        DateChoice: Option "Due Date","Posting Date";
    begin
        Clear(Statement);
        Customer.SetRange("No.", CustomerNo);
        Customer.SetRange("Date Filter", WorkDate());
        Statement.SetTableView(Customer);
        LibraryReportValidation.SetFileName(Customer.TableCaption + Format(CustomerNo));
        Statement.InitializeRequest(false, false, true, false, false, false, '1M+CM', DateChoice::"Due Date", true, WorkDate(), WorkDate());
        Statement.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;
#if not CLEAN23
    local procedure SaveIncomeStatementReport(GLAccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        IncomeStatement: Report "Income statement";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        Clear(IncomeStatement);
        GLAccount.SetRange("No.", GLAccountNo);
        GLAccount.SetFilter("Date Filter", '%1..%2', CalcDate('<-CY+1Y>', WorkDate()), CalcDate('<CY+1Y>', WorkDate()));
        IncomeStatement.SetTableView(GLAccount);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        IncomeStatement.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    local procedure VerifyValueOnReport(GLAccount: Record "G/L Account"; MustBeVisible: Boolean)
    begin
        GLAccount.CalcFields("Net Change");
        LibraryReportValidation.OpenFile();
        if MustBeVisible then
            Assert.IsTrue(LibraryReportValidation.CheckIfValueExists(Format(GLAccount.Name)), ValueMustExistErr)
        else
            Assert.IsFalse(LibraryReportValidation.CheckIfValueExists(Format(GLAccount.Name)), ValueNotExistErr);
    end;
#endif
    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderRequestPageHandler(var Reminder: TestRequestPage Reminder)
    begin
        Reminder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
#if not CLEAN23
    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BalanceSheetReportRequestPageHandler(var BalanceSheet: TestRequestPage "Balance sheet")
    var
        ShowAllVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowAllVariable);
        BalanceSheet.ShowAllAccounts.SetValue(ShowAllVariable);
        BalanceSheet.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;
#endif
}

