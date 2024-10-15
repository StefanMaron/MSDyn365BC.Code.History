codeunit 134976 "ERM Sales Report"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Report]
        isInitialized := false;
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        ColumnTotalLbl: Label 'Total';
        SuccessfullyReversedMessageMsg: Label 'The entries were successfully reversed.';
        UnexpectedMessageMsg: Label 'Unexpected message.';
        TotalCaptionLbl: Label 'Total (LCY)';
        DocumentNoLbl: Label 'Cust_Ledger_Entry_Document_No_';
        DueDateLbl: Label 'Cust_Ledger_Entry_Posting_Date_';
        RemAmountLbl: Label 'Cust_Ledger_Entry_Remaining_Amount_';
        RowNotFoundMsg: Label 'Row does not exist.';
        OverdueEntriesLbl: Label 'Overdue Entries';
        PhoneNoLbl: Label 'Customer_Phone_No_';
        RowNotFoundErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2.', Comment = '%1=Field Caption,%2=Field Value;';
        VALVATAmountLCYTok: Label 'VALVATAmountLCY';
        VALVATAmtLCYTok: Label 'VALVATAmtLCY';
        VALVATBaseLCYTok: Label 'VALVATBaseLCY';
        VATPer_VATCounterLCYTok: Label 'VATCtrl164_VATAmtLine';
        VATIdentifier_VATCounterLCYTok: Label 'VATIndCtrl_VATAmtLine';
        PostedAsmLineDescCapTxt: Label 'TempPostedAsmLineDesc';
        PostedAsmLineDescriptionCapTxt: Label 'PostedAsmLineDescription';
        Type: Option Invoice,Shipment;
        CustSummAging_PrintLineLbl: Label 'PrintLine';
        CustSummAging_CurrencyLbl: Label 'Currency2_Code';
        CustSummAging_TotalBalanceLbl: Label 'LineTotalCustBalance_Control67';
        ExcelCountWorksheetsErr: Label 'Saved Excel file has incorrect number of worksheets.';
        SalesInvoiceTxt: Label 'Sales - Invoice %1';
        SalesPrepmtInvoiceTxt: Label 'Sales - Prepayment Invoice %1';
        SalesTaxInvoiceTxt: Label 'Sales - Tax Invoice %1';
        InvoiceTxt: Label 'Invoice';
        TaxInvoiceTxt: Label 'Tax Invoice';
        EmptyReportDatasetTxt: Label 'There is nothing to print for the selected filters.';

    [Test]
    [HandlerFunctions('CustomerTrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerTrialBalanceReport()
    var
        CustomerNo: Code[20];
        DebitAmount: Decimal;
        CreditAmount: Decimal;
    begin
        // [FEATURE] [Customer - Trial Balance]
        // [SCENARIO] Debit and Credit amounts in Customer - Trial Balance report
        Initialize;

        // [GIVEN] Post Customer ledger entries with Debit Amount = "X", Credit Amount = "Y"
        CustomerNo := CreatePostDebitCreditJournalLines(DebitAmount, CreditAmount, CreateCustomer);

        // [WHEN] Run Customer - Trial Balance report
        RunCustomerTrialBalanceReportForCY(CustomerNo, '', '');

        // [THEN] Reported Debit Amount = "X", Credit Amount  = "Y"
        VerifyCustomerTrialBalanceDCAmounts(CustomerNo, DebitAmount, Abs(CreditAmount));
    end;

    [Test]
    [HandlerFunctions('CustomerTrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerTrialBalanceReportWithDimensions()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        GlobalDim1Value: Code[20];
        GlobalDim2Value: Code[20];
        DebitAmount: Decimal;
        CreditAmount: Decimal;
        DebitAmountDim: Decimal;
        CreditAmountDim: Decimal;
    begin
        // [FEATURE] [Customer - Trial Balance]
        // [SCENARIO 122717] Run Customer - Trial Balance report with dimension filters
        Initialize;

        // [GIVEN] New Dimension Values for Global Dimension: "G1","G2"
        CreateGlobalDimValues(GlobalDim1Value, GlobalDim2Value);
        // [GIVEN] Post Customer ledger entries with Debit Amount = "D" and Credit Amount = "C" without dimensions
        CustomerNo := CreatePostDebitCreditJournalLines(DebitAmount, CreditAmount, CreateCustomer);
        // [GIVEN] Post Customer ledger entries with Debit Amount = "D1" and Credit Amount = "C1" and dimensions "G1","G2"
        DebitAmountDim := LibraryRandom.RandDec(1000, 2);
        CreditAmountDim := -LibraryRandom.RandDec(1000, 2);
        CreateDebitCreditJournalLinesWithDimensions(
          GenJournalLine, CustomerNo, DebitAmountDim, CreditAmountDim, GlobalDim1Value, GlobalDim2Value);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run Customer - Trial Balance report with filters by dimensions "G1","G2"
        RunCustomerTrialBalanceReportForCY(CustomerNo, GlobalDim1Value, GlobalDim2Value);

        // [THEN] Debit and Credit Amounts = "D1", "C1" are filtered and shown in report.
        VerifyCustomerTrialBalanceDCAmounts(CustomerNo, DebitAmountDim, Abs(CreditAmountDim));
        // [THEN] Sums of Debit and Credit Amounts = "D" + "D1", "C" + "C1" are not shown in report
        LibraryReportDataset.AssertElementWithValueNotExist('PeriodDebitAmt', DebitAmount + DebitAmountDim);
        LibraryReportDataset.AssertElementWithValueNotExist('PeriodDebitAmt', Abs(CreditAmount + CreditAmountDim));
    end;

    [Test]
    [HandlerFunctions('CustomerOrderDetailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OrderDetail()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineAmount: Decimal;
    begin
        // Create a Sales Order with Currency for New Customer and Verify data showing in Customer Order Detail Report.

        // Setup.
        Initialize;
        CreateSalesOrder(SalesHeader, SalesLine, CreateCurrency, CreateCustomer);
        LineAmount := Round(LibraryERM.ConvertCurrency(SalesLine."Line Amount", SalesHeader."Currency Code", '', WorkDate));

        // Exercise: Generate the Customer Order Detail Report.
        RunCustomerOrderDetailReport(SalesLine."Sell-to Customer No.", true);

        // Verify: Check that the value of Amount in Customer Order Detail equal to the value of Amount in corresponding Sales Line.
        VerifyLineAmtCustomerOrderDetailReport(SalesLine."No.", LineAmount);
    end;

    [Test]
    [HandlerFunctions('CustomerOrderDetailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OrderDetailInLCY()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create a Sales Order for New Customer and Verify data showing in Customer Order Detail Report.

        // Setup.
        Initialize;
        CreateSalesOrder(SalesHeader, SalesLine, '', CreateCustomer);

        // Exercise: Generate the Customer Order Detail Report.
        RunCustomerOrderDetailReport(SalesLine."Sell-to Customer No.", false);

        // Run Customer Order Detail and Verify Order value showing in Report.
        VerifyLineAmtCustomerOrderDetailReport(SalesLine."No.", SalesLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('CustomerOrderSummaryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OrderSummary()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create a Sales Order for New Customer and Verify value of Balance in Order Summary is equal to the value of Amount
        // in corresponding Sales Line.

        // Setup.
        Initialize;
        CreateSalesOrder(SalesHeader, SalesLine, '', CreateCustomer);

        // Exercise: Generate the Customer Order Summary Report.
        RunCustOrderSummaryReport(SalesLine."Sell-to Customer No.", true);

        // Verify: Check that the value of Balance in Order Summary is equal to the value of Amount in corresponding Sales Line.
        VerifyCustOrderSummary(SalesLine, SalesHeader."Currency Factor");
    end;

    [Test]
    [HandlerFunctions('CustomerOrderSummaryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OrderSummaryLCY()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create a Sales Order using Currency for New Customer and Verify value of Balance in Order Summary is equal to the value of Amount
        // in corresponding Sales Line.

        // Setup.
        Initialize;
        CreateSalesOrder(SalesHeader, SalesLine, CreateCurrency, CreateCustomer);

        // Exercise: Generate the Customer Order Summary Report.
        RunCustOrderSummaryReport(SalesLine."Sell-to Customer No.", false);

        // Verify: Check that the value of Balance in Order Summary is equal to the value of Amount in corresponding Sales Line.
        VerifyCustOrderSummary(SalesLine, SalesHeader."Currency Factor");
    end;

    [Test]
    [HandlerFunctions('CustomerSummaryAgingSimpRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SummaryAgingSimp()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        InvoiceAmount: Decimal;
        NoOfDays: Integer;
    begin
        // Setup: Create Customer, Make and Post Invoice Entry from General Journal Line.
        Initialize;
        LibrarySales.CreateCustomer(Customer);
        NoOfDays := 30 * LibraryRandom.RandInt(4);
        InvoiceAmount := LibraryRandom.RandDec(1000, 2);
        CreatePostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer."No.", '', InvoiceAmount, WorkDate);
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer."No.", '', InvoiceAmount,
          CalcDate('<' + Format(-NoOfDays) + 'D>', WorkDate));

        // Exercise: Generate Customer Summary Aging Simp Report as Output file and save as XML.
        LibraryVariableStorage.Enqueue(WorkDate);
        LibraryVariableStorage.Enqueue(Customer."No.");
        REPORT.Run(REPORT::"Customer - Summary Aging Simp.");

        // Verify: Verify Customer Summary Aging Simp Values.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('Customer__No__', Customer."No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'No_Customer', Customer."No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDueLCY_5__Control25', InvoiceAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDueLCY_5__Control37', InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('CustomerTopTenListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TopTenListSalesLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        ShowType: Option "Sales (LCY)","Balance (LCY)";
        SalesLCY: Decimal;
    begin
        // Setup: Create Customer, Make and Post Invoice Entry from General Journal Line.
        Initialize;
        LibrarySales.CreateCustomer(Customer);
        SalesLCY := GetCustomerSalesLCY + LibraryRandom.RandDec(100, 2);
        CreatePostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer."No.", '', SalesLCY, WorkDate);

        // Exercise: Generate Customer Summary Aging Simp Report as Output file and save as XML.
        LibraryVariableStorage.Enqueue(ShowType::"Sales (LCY)");
        LibraryVariableStorage.Enqueue(Customer."No.");
        REPORT.Run(REPORT::"Customer - Top 10 List");

        // Verify: Verify Customer Top 10 List Report for Sales LCY.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_Customer', Customer."No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'No_Customer', Customer."No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesLCY_Customer', SalesLCY);
    end;

    [Test]
    [HandlerFunctions('CustomerTopTenListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TopTenListBalanceLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        ShowType: Option "Sales (LCY)","Balance (LCY)";
        BalanceLCY: Decimal;
    begin
        // Setup: Create Customer, Make and Post Invoice Entry from General Journal Line.
        Initialize;
        LibrarySales.CreateCustomer(Customer);
        BalanceLCY := GetCustomerBalanceLCY + LibraryRandom.RandDec(100, 2);
        CreatePostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer."No.", '', BalanceLCY, WorkDate);

        // Exercise: Generate Customer Summary Aging Simp Report as Output file and save as XML.
        LibraryVariableStorage.Enqueue(ShowType::"Balance (LCY)");
        LibraryVariableStorage.Enqueue(Customer."No.");
        REPORT.Run(REPORT::"Customer - Top 10 List");

        // Verify: Verify Customer Top 10 List Report for Balance LCY.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_Customer', Customer."No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'No_Customer', Customer."No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('BalanceLCY_Customer', BalanceLCY);
    end;

    [Test]
    [HandlerFunctions('CustomerListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerList()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer - List]
        // [SCENARIO] Value of Credit Limit LCY in Customer List matches the value of Credit Limit LCY in corresponding Customer.

        // [GIVEN] Customer with Credit Limit LCY field.
        Initialize;
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Credit Limit (LCY)", LibraryRandom.RandInt(10));
        Customer.Modify(true);

        // [WHEN] Generate the Customer-List report.
        RunCustomerListReport(Customer);

        // [THEN] Value of Credit Limit LCY in Customer List is equal to the value of Credit Limit LCY in corresponding Customer.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('Customer__No__', Customer."No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'No_Customer', Customer."No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('Customer__Credit_Limit__LCY__', Customer."Credit Limit (LCY)");
    end;

    [Test]
    [HandlerFunctions('CustomerListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerListFilterStringWithGlobalDimCaptions()
    var
        Customer: Record Customer;
        DimValueCode: array[2] of Code[20];
        ExpectedFilterString: Text;
    begin
        // [FEATURE] [Customer - List]
        // [SCENARIO 376798] "Customer - List" report prints global dimension captions in case of customer dimension filters
        Initialize;
        UpdateGlobalDims;

        // [GIVEN] General Ledger Setup with two global dimensions: "Department", "Project".
        // [GIVEN] Customer "C" with two default dimensions: Code = "Department", Value = "ADM"; Code = "Project", Value = "VW".
        CreateCustomerWithDefaultGlobalDimValues(Customer, DimValueCode);

        // [WHEN] Run "Customer - List" report with following filters: "No." = "C"; "Department Code" = "ADM", "Project Code" = "VW"
        Customer.SetFilter("Global Dimension 1 Code", DimValueCode[1]);
        Customer.SetFilter("Global Dimension 2 Code", DimValueCode[2]);
        RunCustomerListReport(Customer);

        // [THEN] Report prints customer "C" with following filter string: "No.: <"C">, Department Code: ADM, Project Code: VW"
        ExpectedFilterString :=
          StrSubstNo('%1: %2, %3: %4, %5: %6',
            Customer.FieldName("No."), Customer."No.",
            Customer.FieldCaption("Global Dimension 1 Code"), DimValueCode[1],
            Customer.FieldCaption("Global Dimension 2 Code"), DimValueCode[2]);

        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('Customer__No__', Customer."No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('CustFilter', ExpectedFilterString);
    end;

    [Test]
    [HandlerFunctions('CustomerRegisterRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerRegister()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Check value of Original Amount in Customer Register matches the value of Amount in corresponding General Journal Line without
        // Currency.

        // Setup: Create a Customer and Post General Journal Line with Invoice.
        Initialize;
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer, '', LibraryRandom.RandDec(100, 2), WorkDate);

        // Excercise: Generate the Customer Register report and Verify Data on it without LCY Amount.
        CustLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        CustLedgerEntry.FindLast;
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Entry No.");
        RunAndVerifyCustomerRegister(GenJournalLine."Document No.", GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('CustomerRegisterRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerRegisterWithLCY()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OriginalAmountLCY: Decimal;
    begin
        // Check value of Original Amount in Customer Register matches the value of Amount in corresponding General Journal Line with
        // Currency.

        // Setup: Create a Customer and Post General Journal Line with Invoice.
        Initialize;
        LibraryERM.FindCurrency(Currency);
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer, Currency.Code, LibraryRandom.RandDec(100, 2),
          WorkDate);
        OriginalAmountLCY :=
          Round(LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", '', GenJournalLine."Posting Date"));

        // Excercise: Generate the Customer Register report and Verify Data on it with LCY Amount.
        CustLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        CustLedgerEntry.FindLast;
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Entry No.");
        RunAndVerifyCustomerRegister(GenJournalLine."Document No.", OriginalAmountLCY);
    end;

    [Test]
    [HandlerFunctions('CustomerDetailTrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetailTrialBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check value of Amount in Customer Detail Trial Balance matches the value of Amount in corresponding General Journal Line
        // without Currency.

        // Setup: Create a Customer and Post General Journal Line with Invoice.
        Initialize;
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer, '', LibraryRandom.RandDec(100, 2), WorkDate);

        // Exercise: Generate the Customer Detail Trial Balance Report.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");
        RunAndVerifyCustomerTrialBal(GenJournalLine, GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('CustomerDetailTrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetailTrialBalanceLCY()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        AmountLCY: Decimal;
    begin
        // Check value of Amount in Customer Detail Trial Balance matches the value of Amount in corresponding General Journal Line
        // With Currency.

        // Setup: Create a Customer and Post General Journal Line with Invoice.
        Initialize;
        LibraryERM.FindCurrency(Currency);
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer, Currency.Code, LibraryRandom.RandDec(100, 2),
          WorkDate);
        AmountLCY :=
          Round(LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", '', GenJournalLine."Posting Date"));

        // Exercise: Generate the Customer Detail Trial Balance Report.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");
        RunAndVerifyCustomerTrialBal(GenJournalLine, AmountLCY);
    end;

    [Test]
    [HandlerFunctions('CustomerSummaryAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerSummaryAging()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check value of Balance in Customer Summary Aging matches the value of Amount in corresponding General Journal Line
        // without Currency.

        // Setup: Create a Customer and Post General Journal Line with Invoice.
        Initialize;
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer, '', LibraryRandom.RandDec(100, 2), WorkDate);

        // Generate the Customer Summary Aging Report and Verify without LCY Amount.
        RunAndVerifyCustSummaryAging(GenJournalLine."Account No.", false, GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('CustomerSummaryAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerSummaryAgingWithLCY()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        AmountLCY: Decimal;
    begin
        // Check value of Balance in Customer Summary Aging matches the value of Amount in corresponding General Journal Line
        // with Currency.

        // Setup: Create a Customer and Post General Journal Line with Invoice.
        Initialize;
        LibraryERM.FindCurrency(Currency);
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer, Currency.Code, LibraryRandom.RandDec(100, 2),
          WorkDate);
        AmountLCY :=
          Round(LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", '', GenJournalLine."Posting Date"));

        // Generate the Customer Summary Aging Report and Verify with LCY Amount.
        RunAndVerifyCustSummaryAging(GenJournalLine."Account No.", true, AmountLCY);
    end;

    [Test]
    [HandlerFunctions('CustomerDetailedAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetailedAging()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
    begin
        // Check value of Remaining Amount in Customer Detailed Aging matches the value of Amount in corresponding General Journal Line.

        // Setup: Create a Customer and Post General Journal Line with Invoice.
        Initialize;
        LibrarySales.CreateCustomer(Customer);
        PaymentTerms.Get(Customer."Payment Terms Code");  // Added fix to make test world ready.
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer, '', LibraryRandom.RandDec(100, 2), WorkDate);

        // Exercise: Generate the Customer Detailed Aging Report.
        RunCustomerDetailedAging(GenJournalLine);

        // Verify: Check that the value of Remaining Amount in Customer Detailed Aging is equal to the value of Amount in
        // corresponding General Journal Line.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('Cust_Ledger_Entry_Posting_Date_', Format(GenJournalLine."Posting Date"));
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'Cust_Ledger_Entry_Posting_Date_', Format(GenJournalLine."Posting Date")));
        LibraryReportDataset.AssertCurrentRowValueEquals('Cust_Ledger_Entry_Remaining_Amount_', GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerItemSales()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        PostedDocumentNo: Code[20];
    begin
        // Check that correct Amount is available on Customer Item Sales Report after posting Sales Order.

        // Setup.
        Initialize;
        PostedDocumentNo := CreateAndPostSalesOrder(SalesHeader, SalesLine);

        // Exercise: Save the Report in XML Format and fetch the Value of Amount Field for Verification.
        LibraryVariableStorage.Enqueue(SalesHeader."Sell-to Customer No.");
        REPORT.Run(REPORT::"Customer/Item Sales");
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('ValueEntryBuffer__Item_No__', SalesLine."No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'ValueEntryBuffer__Item_No__', SalesLine."No."));
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'ValueEntryBuffer__Sales_Amount__Actual___Control44', SalesLine.Amount);

        // Verify: Verify that correct Amount is available on Posted Sales Invoice Line.
        SalesInvoiceLine.SetRange("Document No.", PostedDocumentNo);
        SalesInvoiceLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceLine.FindFirst;
        SalesInvoiceLine.TestField("Line Amount", SalesLine.Amount);
    end;

    [Test]
    [HandlerFunctions('CustomerSalesListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerSalesListWithAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        PostedDocumentNo: Code[20];
    begin
        // Check that correct Amount is Available on Customer Sales List Report after posting Sales Order.

        // Create and Post Sales Order, Save Customer Sales List Report in XML with Hide Address TRUE.
        Initialize;
        PostedDocumentNo := CreateAndPostSalesOrder(SalesHeader, SalesLine);

        // Exercise.
        LibraryVariableStorage.Enqueue(SalesHeader."Sell-to Customer No.");
        REPORT.Run(REPORT::"Customer - Sales List");

        // Verify: Verify that Amount Fetched from the Report is matching with Posted Sales Invoice Amount.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('Customer__No__', SalesHeader."Sell-to Customer No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'Customer__No__', SalesHeader."Sell-to Customer No."));

        SalesInvoiceHeader.Get(PostedDocumentNo);
        SalesInvoiceHeader.CalcFields(Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('AmtSalesLCY', SalesInvoiceHeader.Amount);
    end;

    [Test]
    [HandlerFunctions('CustomerSalesListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerSalesListWithAddress()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedDocumentNo: Code[20];
    begin
        // Check that correct Address is Available on Customer Sales List Report after posting Sales Order.

        // Create and Post Sales Order, Save Customer Sales List Report in XML with Hide Address FALSE.
        Initialize;
        PostedDocumentNo := CreateAndPostSalesOrder(SalesHeader, SalesLine);

        // Verify: Verify that Address fetched from Report is matching with Address on Posted Sales Invoice.
        LibraryVariableStorage.Enqueue(SalesHeader."Sell-to Customer No.");
        REPORT.Run(REPORT::"Customer - Sales List");
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('Customer_Name', SalesHeader."Sell-to Customer No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'Customer_Name', SalesHeader."Sell-to Customer No."));

        // Verify: Verify that Amount Fetched from the Report is matching with Posted Sales Invoice Amount.
        SalesInvoiceHeader.Get(PostedDocumentNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustAddr_2_', SalesInvoiceHeader."Sell-to Address");
    end;

    [Test]
    [HandlerFunctions('CustomerDocumentNosRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDocumentNos()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        PostedDocumentNo: Code[20];
    begin
        // Check that Customer Document Nos. Report contains correct Customer after Posting Sales Order.

        // Setup:
        Initialize;
        PostedDocumentNo := CreateAndPostSalesOrder(SalesHeader, SalesLine);

        // Exercise: Save the Report in XML and fetch the value of Customer No. Field for further use.
        CustLedgerEntry.SetRange("Document No.", PostedDocumentNo);
        CustLedgerEntry.FindLast;
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Customer No.");
        REPORT.Run(REPORT::"Customer Document Nos.");
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('CustLedgerEntry__Document_No__', PostedDocumentNo);
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'CustLedgerEntry__Document_No__', PostedDocumentNo));

        // Verify: Verify that Customer No. fetched from Report is matching with Posted Sales Invoice's Customer.
        SalesInvoiceHeader.Get(PostedDocumentNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustLedgerEntry__Customer_No__', SalesInvoiceHeader."Sell-to Customer No.");
    end;

    [Test]
    [HandlerFunctions('StatementReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OverdueEntriesStatementReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        PeriodLength: DateFormula;
    begin
        // Verify Overdue Entries in Statement Report when Print Overdue Entries option is True.

        // Setup: Create and post General Journal Line, apply partial Payment over the Invoice with Random Values.
        Initialize;
        Amount := LibraryRandom.RandDec(1000, 2);
        PostJournalLines(GenJournalLine, CreateCustomer, Amount, -Amount / 2);
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');

        // Exercise: Save Statement Report for the Customer Created.
        SaveStatementReport(GenJournalLine."Account No.", WorkDate, true, false, false, false, PeriodLength);

        // Verify Remaining Amount in Statement Report in Overdue Entries.
        LibraryReportDataset.LoadDataSetFile;
        VerifyOverDueEntry(GenJournalLine."Posting Date", Amount / 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,StatementReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReversedEntriesStatementReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        PeriodLength: DateFormula;
    begin
        // Verify Reversed Entries in Statement Report When Print Reversed Entries option is True.

        // Setup: Create and post General Journal Line with Random Values and Reverse the Entry.
        Initialize;
        Amount := LibraryRandom.RandDec(1000, 2);
        CreatePostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer, '', Amount, GetPostingDate);
        ReverseTransaction(FindGLEntry(GenJournalLine."Document No."));
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');

        // Exercise: Save Statement Report for the Customer Created.
        SaveStatementReport(GenJournalLine."Account No.", GenJournalLine."Posting Date", false, true, false, false, PeriodLength);

        // Verify: Verify Amount in Statement Report after Entries has been Reversed.
        LibraryReportDataset.LoadDataSetFile;
        VerifyAmountInMultipleRows(GenJournalLine."Document No.", Amount);
    end;

    [Test]
    [HandlerFunctions('StatementReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure UnappliedEntryStatementReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        PeriodLength: DateFormula;
    begin
        // Verify Unapplied Entries in Statement Report when Print Unapplied Entries option is True.

        // Setup: Create and post General Journal Line,apply and Unapply Invoice and Payment with Random Values.
        Initialize;
        Amount := LibraryRandom.RandDec(1000, 2);
        PostJournalLines(GenJournalLine, CreateCustomer, Amount, -Amount);
        UnapplyCustLedgerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');

        // Exercise: Save Statement Report for the Customer Created.
        SaveStatementReport(GenJournalLine."Account No.", WorkDate, false, false, true, false, PeriodLength);

        // Verify: Verify Remaining Amount in Statement Report after Entries has been Unapplied.
        LibraryReportDataset.LoadDataSetFile;
        VerifyAmountInMultipleRows(GenJournalLine."Document No.", Amount);
    end;

    [Test]
    [HandlerFunctions('StatementReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintAgingBandStatementReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        PeriodLength: DateFormula;
        PostingDate: Date;
    begin
        // Verify Statement Report when Include Aging Band option is True.

        // Setup: Create and post General Journal Line with Random Value.
        Initialize;
        Amount := LibraryRandom.RandDec(1000, 2);
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        PostingDate := CalcDate(PeriodLength, WorkDate);
        CreatePostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer, '', Amount, PostingDate);

        // Exercise: Save Statement Report for the Customer Created.
        SaveStatementReport(GenJournalLine."Account No.", WorkDate, false, false, false, true, PeriodLength);

        // Verify Remaining Amount in Statement Report.
        LibraryReportDataset.LoadDataSetFile;
        VerifyRemainAmtInCustLedgEntry(PostingDate, Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,StatementReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerStatementReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        PeriodLength: DateFormula;
        PostingDate: Date;
    begin
        // Verify Statement Report when Print Overdue Entries, Print Reversed Entries, Print Unapplied Entries and Include Aging Band
        // Option are all set to True.

        // Setup: Create and post General Journal Line, Reverse the Entry, Unapply Payment Over the Invoice with Random Values.
        Initialize;
        Amount := LibraryRandom.RandDec(100, 2);
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        PostingDate := CalcDate(PeriodLength, WorkDate);
        CreatePostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer, '', Amount, PostingDate);
        ReverseTransaction(FindGLEntry(GenJournalLine."Document No."));
        PostJournalLines(GenJournalLine, GenJournalLine."Account No.", Amount, -Amount);
        UnapplyCustLedgerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");

        // Exercise: Save Statement Report for the Customer Created.
        SaveStatementReport(GenJournalLine."Account No.", WorkDate, true, true, true, true, PeriodLength);

        // Verify: Verify Amount in Statement Report in Overdue Entries and Amount after Unapplied Entries.
        LibraryReportDataset.LoadDataSetFile;
        VerifyOverDueEntry(GenJournalLine."Posting Date", -Amount);
    end;

    [Test]
    [HandlerFunctions('OrderConfirmationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OrderConfirmationReportWithPostingDateBlankOnSalesOrder()
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        OrderConfirmation: Report "Order Confirmation";
        DefaultPostingDate: Option;
    begin
        // Check Saved Sales Order Report to Verify that program generates report.

        // Setup: Setup Sales and Receivables Setup, Calculate Invoice Discount and Create Sales Order.
        Initialize;
        UpdateSalesReceivablesSetup(DefaultPostingDate, SalesReceivablesSetup."Default Posting Date"::"No Date");
        SetupInvoiceDiscount(CustInvoiceDisc);

        // Create Sales Order and Calculate Invoice Discount.
        CreateSalesOrder(SalesHeader, SalesLine, CreateCurrency, CustInvoiceDisc.Code);
        ModifyUnitPriceInSalesLine(SalesLine, CustInvoiceDisc."Minimum Amount");
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);

        // Exercise: Generate Report as external file for Sales Order.
        Clear(OrderConfirmation);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("No.", SalesHeader."No.");
        OrderConfirmation.SetTableView(SalesHeader);
        Commit();
        OrderConfirmation.Run;

        // Verify: Verify that Saved files have some data.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('No_SalesHeader', SalesHeader."No.");

        // Tear Down: Cleanup of Setup Done.
        UpdateSalesReceivablesSetup(DefaultPostingDate, DefaultPostingDate);
    end;

    [Test]
    [HandlerFunctions('CustomerSummaryAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerSummaryAgingWithShowAmountInLCYTrue()
    begin
        // Check the Value of Total(LCY) in Customer Summary Aging Report when Show Amounts In LCY is TRUE.
        CustomerSummaryAgingReport(true);
    end;

    [Test]
    [HandlerFunctions('CustomerSummaryAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerSummaryAgingWithShowAmountInLCYFalse()
    begin
        // Check the Value of Total(LCY) in Customer Summary Aging Report when Show Amounts In LCY is FALSE.
        CustomerSummaryAgingReport(false);
    end;

    local procedure CustomerSummaryAgingReport(ShowAmountsInLCY: Boolean)
    var
        Customer: Record Customer;
        Amount: Decimal;
    begin
        // Setup: Create a Customer and Post General Journal Lines without Currency and with Currency.
        Initialize;
        LibrarySales.CreateCustomer(Customer);
        Amount := LibraryRandom.RandDec(1000, 2);
        CreateAndPostInvoice(Customer."No.", '', Amount);
        CreateAndPostInvoice(Customer."No.", CreateCurrency, Amount);

        // Exercise: Run the Customer Summary Aging Report.
        RunCustomerSummaryAgingReport(Customer."No.", ShowAmountsInLCY);

        // Verify: Check that the value of Total(LCY) in Customer Summary Aging Report is equal to Customer."Balance (LCY)".
        LibraryReportDataset.LoadDataSetFile;
        VerifyTotalLCYOnCustomerSummaryAgingReport(Customer);
    end;

    [Test]
    [HandlerFunctions('CustomerOrderSummaryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOrderSummaryWithoutCurrencyFilter()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        // Check the Value of Total(LCY) in Customer Order Report when Show Amount LCY is FALSE and Currency Filter is blank.

        // Setup: Create Customer with currency and then create a sales order.
        Initialize;
        CreateCustomerWithCurrencyCode(Customer);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."Currency Code", Customer."No.");

        // Exercise: Run Customer Order Summary Report with currency filter blank and Show Amount LCY is FALSE.
        LibraryVariableStorage.Enqueue(WorkDate);
        LibraryVariableStorage.Enqueue(false);
        RunCustomerOrderSummaryReport(Customer);

        // Verify: Verify that Totoal (LCY) shows the correct value in local currency and check that currency code does not exist in the report.
        LibraryReportDataset.LoadDataSetFile;
        VerifyTotalLCYOnCustomerOrderSummary(SalesLine."Line Amount" / SalesHeader."Currency Factor");
        asserterror LibraryReportDataset.AssertElementWithValueExists('', SalesHeader."Currency Code");
    end;

    [Test]
    [HandlerFunctions('CustomerOrderSummaryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOrderSummaryWithCurrencyFilter()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        // Check the Value of Total(LCY) in Customer Order Report when Show Amount LCY is FALSE and Currency Filter is not blank.

        // Setup: Create Customer with currency and then create a sales order.
        Initialize;
        CreateCustomerWithCurrencyCode(Customer);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."Currency Code", Customer."No.");

        // Exercise: Run Customer Order Summary Report with currency filter not blank and Show Amount LCY is FALSE.
        LibraryVariableStorage.Enqueue(WorkDate);
        LibraryVariableStorage.Enqueue(false);
        Customer.SetRange("Currency Filter", SalesHeader."Currency Code");
        RunCustomerOrderSummaryReport(Customer);

        // Verify: Verify that Totoal (LCY) shows the correct value in local currency and check that Currency Code is showing in the report.
        LibraryReportDataset.LoadDataSetFile;
        VerifyTotalLCYOnCustomerOrderSummary(SalesLine."Line Amount" / SalesHeader."Currency Factor");
        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists('CurrencyCode_SalesLine', SalesHeader."Currency Code");
    end;

    [Test]
    [HandlerFunctions('CustomerDetailedAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetailedAgingReportForSorting()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLinePayment: Record "Gen. Journal Line";
    begin
        // Verify that the entries are sorted according to Due Date in Customer Detailed Aging.

        // Setup: Create a Customer and Post General Journal Lines with Random and different Amounts.
        Initialize;
        LibrarySales.CreateCustomer(Customer);
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer."No.", '', LibraryRandom.RandDec(100, 2), WorkDate);
        CreatePostGeneralJournalLine(
          GenJournalLinePayment, GenJournalLinePayment."Document Type"::Payment, GenJournalLine."Account No.", '',
          2 * -LibraryRandom.RandDec(100, 2), CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate));

        // Exercise: Run Customer Detailed Aging Report.
        RunCustomerDetailedAging(GenJournalLinePayment);

        // Verify: Check that the entries are sorted according to Due Date in Customer Detailed Aging.
        LibraryReportDataset.LoadDataSetFile;
        VerifyCustomerDetailedAging(GenJournalLine."Document No.", GenJournalLine."Due Date");
        VerifyCustomerDetailedAging(GenJournalLinePayment."Document No.", GenJournalLinePayment."Due Date");
    end;

    [Test]
    [HandlerFunctions('CustomerDetailedAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetailedAgingReportForDuplicateRow()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLinePayment: Record "Gen. Journal Line";
    begin
        // Verify that the first line in detailed entries displays only once.

        // Setup: Create a Customer and Post General Journal Lines with Random and different Amounts. Run Customer Detailed Aging Report.
        Initialize;
        LibrarySales.CreateCustomer(Customer);
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer."No.", '', LibraryRandom.RandDec(100, 2), WorkDate);
        CreatePostGeneralJournalLine(
          GenJournalLinePayment, GenJournalLinePayment."Document Type"::Payment, GenJournalLine."Account No.", '',
          2 * -LibraryRandom.RandDec(100, 2), CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate));
        RunCustomerDetailedAging(GenJournalLinePayment);
        LibraryReportDataset.SetRange(DocumentNoLbl, '');
        LibraryReportDataset.GetNextRow;

        // Exercise.
        asserterror LibraryReportDataset.AssertCurrentRowValueEquals(RemAmountLbl, GenJournalLine.Amount);

        // Verify: Check that the first line in detailed entries displays only once.
        Assert.ExpectedError(RowNotFoundMsg);
    end;

    [Test]
    [HandlerFunctions('CustomerDetailedAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustInfoInCustomerDetailedAgingReport()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify that the Phone No. displayed correctly in Customer Detailed Aging Report.

        // Setup: Create a Customer and Post General Journal Line with Random Amount.
        Initialize;
        Customer.Get(CreateCustomer);
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer."No.", '', LibraryRandom.RandDec(100, 2), WorkDate);

        // Exercise: Run Customer Detailed Aging Report.
        RunCustomerDetailedAging(GenJournalLine);

        // Verify: Verify that the Phone No. displayed correctly in Customer Detailed Aging.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(PhoneNoLbl, Customer."Phone No.");
    end;

    [Test]
    [HandlerFunctions('CustomerOrderSummaryExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalValueInCustomerOrderSummaryReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Verify the value of Total in Customer Order Summary Report is equal to the total value of Amount in corresponding Sales Lines.

        // Setup: Create Customer, create Sales Order with one Sales Line
        Initialize;
        CreateSalesOrder(SalesHeader, SalesLine, '', CreateCustomer);

        // Create one more Sales Line
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine.Type::Item, SalesLine."No.", LibraryRandom.RandDec(100, 2));

        // Exercise: Generate the Customer Order Summary Report.
        RunCustOrderSummaryReport(SalesLine."Sell-to Customer No.", false);

        // Verify: Check that the value of Total in Customer Order Summary is equal to the total value of Amount in corresponding Sales Lines.
        VerifyCustOrderSummaryTotalValue(SalesLine."Sell-to Customer No.", SalesLine."Line Amount" + SalesLine2."Line Amount");
    end;

    [Test]
    [HandlerFunctions('CustomerOrderSummaryExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TotalValueForLCYInCustomerOrderSummaryReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        Customer: Record Customer;
    begin
        // Verify the value of Total LCY in Customer Order Summary Report is equal to the total LCY value of Amount in corresponding Sales Lines.

        // Setup: Create Customer with currency code, create Sales Order with one Sales Line
        Initialize;
        CreateCustomerWithCurrencyCode(Customer);
        CreateSalesOrder(SalesHeader, SalesLine, CreateCurrency, Customer."No.");

        // Create one more Sales Line
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine.Type::Item, SalesLine."No.", LibraryRandom.RandDec(100, 2));

        // Exercise: Generate the Customer Order Summary Report.
        RunCustOrderSummaryReport(SalesLine."Sell-to Customer No.", true);

        // Verify: Check that the value of Total LCY in Customer Order Summary is equal to the total LCY value of Amount in corresponding Sales Lines.
        VerifyCustOrderSummaryTotalValue(
          SalesLine."Sell-to Customer No.", ConvertCurrency(SalesLine."Line Amount", SalesHeader."Currency Code") +
          ConvertCurrency(SalesLine2."Line Amount", SalesHeader."Currency Code"));
    end;

    [Test]
    [HandlerFunctions('CustomerOrderDetailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOrderDetailReportWithTotal()
    var
        CustomerNo: Code[20];
        ExpectedTotal: Decimal;
    begin
        // Verify Total displayed correctly in Customer Order Detail Report.

        // Setup: Create a Customer, create one Sales Order with two Lines.
        Initialize;
        CreateSalesOrderWithTwoLines(CustomerNo, ExpectedTotal);

        // Exercise: Generate the Customer Order Detail report.
        RunCustomerOrderDetailReport(CustomerNo, true);

        // Verify: verify Total displayed correctly in Customer Order Detail report.
        VerifyTotalOnCustomerOrderDetailReport(CustomerNo, ExpectedTotal);
    end;

    [Test]
    [HandlerFunctions('CustomerOrderSummaryExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOrderSummaryReportWithShowAmountTrue()
    var
        CustomerNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        // Verify Amount of a duration displayed correctly in Customer Order Summary Report.

        // Setup: Create a Customer, create one Sales Order with two Lines.
        Initialize;
        CreateSalesOrderWithTwoLines(CustomerNo, ExpectedAmount);

        // Exercise: Generate the Customer Order Summary report.
        RunCustOrderSummaryReport(CustomerNo, true);

        // Verify: Check that the value of Balance in Order Summary is equal to the value of Amount in corresponding duration.
        VerifyAmountOnCustomerOrderSummaryReport(CustomerNo, ExpectedAmount);
    end;

    [Test]
    [HandlerFunctions('CustomerOrderDetailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOrderDetailReportWithReleasedDocument()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        ExpectedTotal: Decimal;
    begin
        // Verify Outstanding Orders and Total for released order displayed correctly in Customer Order Detail Report.

        // Setup: Create a Customer, create one Sales Order with two Lines.
        Initialize;
        CreateSalesOrderWithTwoLines(CustomerNo, ExpectedTotal);

        // Release the Sales Order.
        ReleaseSalesOrder(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        // Exercise: Generate the Customer - Order Detail report.
        RunCustomerOrderDetailReport(CustomerNo, true);

        // Verify: Verify Outstanding Orders and Total displayed correctly in Customer Order Detail report.
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        VerifyOutstandingOrdersAndTotalOnCustomerOrderDetailReport(SalesLine, CustomerNo, ExpectedTotal);
    end;

    [Test]
    [HandlerFunctions('CustomerOrderSummaryExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomeOrderSummaryReportWithReleasedDocument()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        // Verify Amount of a duration displayed correctly in Customer Order Summary Report.

        // Setup: Create a Customer, create one Sales Order with two Lines.
        Initialize;
        CreateSalesOrderWithTwoLines(CustomerNo, ExpectedAmount);

        // Release the Sales Order.
        ReleaseSalesOrder(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        // Exercise: Generate the Customer Order Summary report.
        RunCustOrderSummaryReport(CustomerNo, true);

        // Verify: Check that the value of Balance in Order Summary is equal to the value of Amount in corresponding duration.
        VerifyAmountOnCustomerOrderSummaryReport(CustomerNo, ExpectedAmount);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoicetReportWithEnabledPrintVATSpecInLCY()
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // Setup
        Initialize;
        UpdateGeneralLedgerSetup(true);

        // Excercise
        CreateAndSetupSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        RunSalesInvoiceReport(DocumentNo, false, false, false, 0);

        // Verify
        VerifySalesInvoiceVATAmountInLCY(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('SalesQuoteRequestPageHandler,ConfirmHandler,CreateToDoPageHandler,SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteReportWithEnabledPrintVATSpecInLCY()
    var
        SalesHeader: Record "Sales Header";
        SalesQuoteToOrder: Codeunit "Sales-Quote to Order";
        DocumentNo: Code[20];
        VATAmount: Decimal;
        VATBaseAmount: Decimal;
    begin
        // Setup
        Initialize;
        UpdateGeneralLedgerSetup(true);

        // Excercise
        CreateAndSetupSalesDocument(SalesHeader, SalesHeader."Document Type"::Quote);
        RunSalesQuoteReport(SalesHeader."No.", true, false, false, false);
        // We need store Sales Quote Report's vat amounts to further comparison with
        // posted VAT entry values
        GetSalesQuoteReportVATAmounts(VATAmount, VATBaseAmount);

        SalesQuoteToOrder.Run(SalesHeader);
        SalesQuoteToOrder.GetSalesOrderHeader(SalesHeader);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        RunSalesInvoiceReport(DocumentNo, true, true, false, 0);

        // Verify
        VerifySalesQuoteVATAmountInLCY(DocumentNo, VATAmount, VATBaseAmount);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure LanguageCodeForAssemblyItemsInSalesInvoiceReport()
    begin
        // Check the Language Code should be translated for Assembly Component items in Sales Report 206 (Sales - Invoice).
        PostSalesOrderForAssemblyItemsWithLanguageCode(true, Type::Invoice); // Post Ship and Invoice
    end;

    [Test]
    [HandlerFunctions('SalesShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure LanguageCodeForAssemblyItemsInSalesShipmentReport()
    begin
        // Check the Language Code should be translated for Assembly Component items in Sales Report 208 (Sales - Shipment).
        PostSalesOrderForAssemblyItemsWithLanguageCode(false, Type::Shipment); // Post Ship only
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerGetFilterStringWithDimCaptions()
    var
        Customer: Record Customer;
        FormatDocument: Codeunit "Format Document";
        DimValueCode: array[2] of Code[20];
        ExpectedFilterString: Text;
    begin
        // [FEATURE] [Customer] [UT]
        // [SCENARIO 376798] COD368 "FormatDocument" method GetRecordFiltersWithCaptions() returns customer filter string with global dimension's captions
        Initialize;
        UpdateGlobalDims;

        // [GIVEN] General Ledger Setup with two global dimensions: "Department", "Project".
        // [GIVEN] Customer "C" with following filters: "Department Code" = "ADM", "Project Code" = "VW".
        CreateCustomerWithDefaultGlobalDimValues(Customer, DimValueCode);

        // [WHEN] Call COD368 "FormatDocument" method GetRecordFiltersWithCaptions()
        Customer.SetFilter("Global Dimension 1 Code", DimValueCode[1]);
        Customer.SetFilter("Global Dimension 2 Code", DimValueCode[2]);

        // [THEN] Return value = "Department Code: ADM, Project Code: VW"
        ExpectedFilterString :=
          StrSubstNo('%1: %2, %3: %4',
            Customer.FieldCaption("Global Dimension 1 Code"), DimValueCode[1],
            Customer.FieldCaption("Global Dimension 2 Code"), DimValueCode[2]);
        Assert.ExpectedMessage(ExpectedFilterString, FormatDocument.GetRecordFiltersWithCaptions(Customer));
    end;

    [Test]
    [HandlerFunctions('CustomerSummaryAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerSummaryAgingPrintsFCYAndDoesntPrintZeroLCYLines()
    var
        CustomerNo: Code[20];
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
        AmountLCY: Decimal;
        AmountFCY: Decimal;
    begin
        // [FEATURE] [Sales] [Customer - Summary Aging]
        // [SCENARIO 377574] "Customer - Summary Aging" report doesn't print zero balance LCY line and prints non-zero balance FCY line for the same customer
        Initialize;
        AmountLCY := LibraryRandom.RandDecInRange(1000, 2000, 2);
        AmountFCY := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CustomerNo := LibrarySales.CreateCustomerNo;
        CurrencyCode := CreateCurrency;

        // [GIVEN] Two customer invoices: "I1" (FCY 100$), "I2" (LCY)
        CreateAndPostInvoice(CustomerNo, CurrencyCode, AmountFCY);
        InvoiceNo := CreateAndPostInvoice(CustomerNo, '', AmountLCY);
        // [GIVEN] Customer payment in LCY applied to invoice "I2"
        CreateApplyAndPostPayment(CustomerNo, InvoiceNo, '', -AmountLCY);

        // [WHEN] Run "Customer - Summary Aging" report
        RunCustomerSummaryAgingReport(CustomerNo, false);

        // [THEN] Report shows a line with FCY balance 100$
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.MoveToRow(1 + LibraryReportDataset.FindRow(CustSummAging_CurrencyLbl, CurrencyCode));
        LibraryReportDataset.AssertCurrentRowValueEquals(CustSummAging_PrintLineLbl, true);
        LibraryReportDataset.AssertCurrentRowValueEquals(CustSummAging_TotalBalanceLbl, AmountFCY);

        // [THEN] Report doesn't show a line for LCY zero balance
        LibraryReportDataset.Reset();
        LibraryReportDataset.MoveToRow(1 + LibraryReportDataset.FindRow(CustSummAging_CurrencyLbl, ''));
        LibraryReportDataset.AssertCurrentRowValueEquals(CustSummAging_PrintLineLbl, false);
        LibraryReportDataset.AssertCurrentRowValueEquals(CustSummAging_TotalBalanceLbl, 0);
    end;

    [Test]
    [HandlerFunctions('CustomerOrderSummaryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOrderSummaryLCY()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [FCY] [Report]
        // [SCENARIO 381014] Print "Customer - Order Summary" when sales order has a currency code different from the customer's currency code and different from the LCY.

        // [GIVEN] Customer with LCY
        // [GIVEN] Sales Order with Amount = "X", "Amount (LCY)" = "Y" invoiced in foreign currency
        LibrarySales.CreateFCYSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
          LibrarySales.CreateCustomerNo, LibraryInventory.CreateItemNo, 1, '', 0D,
          LibraryERM.CreateCurrencyWithRandomExchRates);
        Commit();

        // [WHEN] Run "Customer - Order Summary" report with "Print in LCY" option
        RunCustOrderSummaryReport(SalesHeader."Sell-to Customer No.", true);

        // [THEN] Printed Sales Amount is equal to "Y"
        VerifyCustomerOrderSummarySalesAmount(SalesHeader, SalesLine);
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintYourReferenceOfPostedSalesCrMemo()
    var
        PostedCrMemoNo: Code[20];
        YourReference: Text[35];
    begin
        // [FEATURE] [Sales - Credit Memo]
        // [SCENARIO 382079] Value of "Your Reference" of Posted Sales Cr. Memo have to printed.
        Initialize;

        // [GIVEN] Posted sales credit memo with "Your Reference" = "Ref"
        CreatePostSalesCrMemoWithYourRef(PostedCrMemoNo, YourReference);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);
        Commit();

        // [WHEN] Print report 207 - "Sales - Credit Memo"
        RunSalesCreditMemoReport(PostedCrMemoNo);

        // [THEN] Caption of "Your reference" contains "Ref"
        VerifyYourReferenceSalesCrMemo(YourReference);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintVATSalesInvoiceWithEmptyLastLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        VATProdPostingGroupCode: Code[20];
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 201015] Report 206 "Sales - Invoice" have to print total of VAT if last line is empty
        Initialize;

        // [GIVEN] Customer with VAT Posting Setup with "VAT %" = 33%
        CustomerNo := CreateCustomerWithVATPostingSetup(VATProdPostingGroupCode);

        // [GIVEN] Sales Invoice with three lines
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        // [GIVEN] First line Amount = 100, Amount Incl. VAT = 133
        CreateSalesLineWithItemWithVATProdPostingGroup(SalesLine, SalesHeader, VATProdPostingGroupCode);

        // [GIVEN] Second line Amount = 200, Amount Icnl. VAT = 266
        CreateSalesLineWithItemWithVATProdPostingGroup(SalesLine, SalesHeader, VATProdPostingGroupCode);

        // [GIVEN] Third line contains only Description (Amount = 0, Amount Incl. VAT = 0)
        CreateEmptySalesLineWithDescription(SalesHeader);
        SalesHeader.CalcFields(Amount, "Amount Including VAT");

        // [GIVEN] Post Sales Invoice
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);
        Commit();

        // [WHEN] Print Sales Invoice
        RunSalesInvoiceReport(PostedDocNo, false, true, false, 0);

        // [THEN] Sales Invoice contains Total Amount = 300
        // [THEN] Sales Invoice contains Total VAT = 99
        // [THEN] Sales Invoice contains Total Amount Incl. VAT = 399
        VerifyAmountsSalesInvoiceReport(SalesHeader.Amount, SalesHeader."Amount Including VAT");
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintVATSalesInvoiceWithEmptyMiddleLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        VATProdPostingGroupCode: Code[20];
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 201015] Report 206 "Sales - Invoice" have to print total of VAT if middle line is empty
        Initialize;

        // [GIVEN] Customer with VAT Posting Setup with "VAT %" = 33%
        CustomerNo := CreateCustomerWithVATPostingSetup(VATProdPostingGroupCode);

        // [GIVEN] Sales Invoice with three lines
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        // [GIVEN] First line Amount = 100, Amount Incl. VAT = 133
        CreateSalesLineWithItemWithVATProdPostingGroup(SalesLine, SalesHeader, VATProdPostingGroupCode);

        // [GIVEN] Second line contains only Description (Amount = 0, Amount Incl. VAT = 0)
        CreateEmptySalesLineWithDescription(SalesHeader);

        // [GIVEN] Third line Amount = 200, Amount Icnl. VAT = 266
        CreateSalesLineWithItemWithVATProdPostingGroup(SalesLine, SalesHeader, VATProdPostingGroupCode);
        SalesHeader.CalcFields(Amount, "Amount Including VAT");

        // [GIVEN] Post Sales Invoice
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);
        Commit();

        // [WHEN] Print Sales Invoice
        RunSalesInvoiceReport(PostedDocNo, false, true, false, 0);

        // [THEN] Sales Invoice contains Total Amount = 300
        // [THEN] Sales Invoice contains Total VAT = 99
        // [THEN] Sales Invoice contains Total Amount Incl. VAT = 399
        VerifyAmountsSalesInvoiceReport(SalesHeader.Amount, SalesHeader."Amount Including VAT");
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintVATSalesInvoiceForLineWithZeroVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        VATProdPostingGroupCode: Code[20];
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 201015] Report 206 "Sales - Invoice" have to print total of VAT if one line has VAT % = 0
        Initialize;

        // [GIVEN] Customer with VAT Posting Setup with "VAT %" = 33%
        CustomerNo := CreateCustomerWithVATPostingSetup(VATProdPostingGroupCode);

        // [GIVEN] Posted Sales Invoice with three lines
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        // [GIVEN] First line Amount = 100, Amount Incl. VAT = 133
        CreateSalesLineWithItemWithVATProdPostingGroup(SalesLine, SalesHeader, VATProdPostingGroupCode);

        // [GIVEN] Second line Amount = 200, Amount Incl. VAT = 266
        CreateSalesLineWithItemWithVATProdPostingGroup(SalesLine, SalesHeader, VATProdPostingGroupCode);

        // [GIVEN] Third line with VAT % = 0, Amount = 300, Amount Incl. VAT = 300
        VATProdPostingGroupCode := CreateVATProdPostingGroupWithPercent(SalesHeader."VAT Bus. Posting Group", 0);
        CreateSalesLineWithItemWithVATProdPostingGroup(SalesLine, SalesHeader, VATProdPostingGroupCode);
        SalesHeader.CalcFields(Amount, "Amount Including VAT");

        // [GIVEN] Post Sales Invoice
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);
        Commit();

        // [WHEN] Print Sales Invoice
        RunSalesInvoiceReport(PostedDocNo, false, true, false, 0);

        // [THEN] Sales Invoice contains Total Amount = 600
        // [THEN] Sales Invoice contains Total VAT = 99
        // [THEN] Sales Invoice contains Total Amount Incl. VAT = 699
        VerifyAmountsSalesInvoiceReport(SalesHeader.Amount, SalesHeader."Amount Including VAT");
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceTotals_InvDiscount_SingleItemLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales - Invoice] [Invoice Discount]
        // [SCENARIO 205340] REP 206 "Sales - Invoice" correctly prints Totals in case of Invoice Discount Amount and one document Item line
        Initialize;

        // [GIVEN] Posted sales order with one Item line and invoice discount: "Line Amount" = 1100, "Invoice Discount Amount" = 100, "Amount" = 1000, "Amount Including VAT" = 1200
        CreateSalesOrder(SalesHeader, SalesLine, '', LibrarySales.CreateCustomerNo);
        SetSalesHeaderInvoiceDiscountAmount(SalesHeader, Round(SalesLine.Amount / 10));
        SalesLine.Find;
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Print the posted sales invoice (REP 206 "Sales - Invoice")
        RunSalesInvoiceReport(PostedDocNo, false, false, false, 0);

        // [THEN] Total section includes:
        // [THEN] Subtotal = 1100
        // [THEN] Invoice Discount Amount = 100
        // [THEN] Amount Excluding VAT = 1000
        // [THEN] VAT Amount = 200
        // [THEN] Amount Including VAT = 1200
        VerifySalesInvoiceTotalsWithDiscount(SalesLine, 'AV', 103);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceTotals_InvDiscount_SecondLineWithZeroAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales - Invoice] [Invoice Discount]
        // [SCENARIO 205340] REP 206 "Sales - Invoice" correctly prints Totals in case of Invoice Discount Amount and when second document Item line has zero quantity
        Initialize;

        // [GIVEN] Sales order with two lines:
        // [GIVEN] Line1: "Type" = "Item", "No." = "ITEM1", "Line Amount" = 1100
        CreateSalesOrder(SalesHeader, SalesLine, '', LibrarySales.CreateCustomerNo);
        // [GIVEN] Line2: "Type" = "Item", "No." = "ITEM2", "Quantity" = 0
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, LibraryInventory.CreateItemNo, 0);
        // [GIVEN] Set Invoice Discount Amount = 100
        SetSalesHeaderInvoiceDiscountAmount(SalesHeader, Round(SalesLine.Amount / 10));
        SalesLine.Find;
        // [GIVEN] Post the order
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Print the posted sales invoice (REP 206 "Sales - Invoice")
        RunSalesInvoiceReport(PostedDocNo, false, false, false, 0);

        // [THEN] Total section includes:
        // [THEN] Subtotal = 1100
        // [THEN] Invoice Discount Amount = 100
        // [THEN] Amount Excluding VAT = 1000
        // [THEN] VAT Amount = 200
        // [THEN] Amount Including VAT = 1200
        VerifySalesInvoiceTotalsWithDiscount(SalesLine, 'AV', 105);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceTotals_InvDiscount_SecondLineWithEmptyNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales - Invoice] [Invoice Discount]
        // [SCENARIO 205340] REP 206 "Sales - Invoice" correctly prints Totals in case of Invoice Discount Amount and when second document Item line has empty "No."
        Initialize;

        // [GIVEN] Sales order with two lines:
        // [GIVEN] Line1: "Type" = "Item", "No." = "ITEM", "Line Amount" = 1100
        CreateSalesOrder(SalesHeader, SalesLine, '', LibrarySales.CreateCustomerNo);
        // [GIVEN] Line2: "Type" = "Item", "No." = ""
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, LibraryInventory.CreateItemNo, 0);
        SalesLine2.Validate("No.", '');
        SalesLine2.Modify(true);
        // [GIVEN] Set Invoice Discount Amount = 100
        SetSalesHeaderInvoiceDiscountAmount(SalesHeader, Round(SalesLine.Amount / 10));
        SalesLine.Find;
        // [GIVEN] Post the order
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Print the posted sales invoice (REP 206 "Sales - Invoice")
        RunSalesInvoiceReport(PostedDocNo, false, false, false, 0);

        // [THEN] Total section includes:
        // [THEN] Subtotal = 1100
        // [THEN] Invoice Discount Amount = 100
        // [THEN] Amount Excluding VAT = 1000
        // [THEN] VAT Amount = 200
        // [THEN] Amount Including VAT = 1200
        VerifySalesInvoiceTotalsWithDiscount(SalesLine, 'AV', 103);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceTotals_InvDiscount_SecondDescriptionLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales - Invoice] [Invoice Discount]
        // [SCENARIO 205340] REP 206 "Sales - Invoice" correctly prints Totals in case of Invoice Discount Amount and when second document line is a description line
        Initialize;

        // [GIVEN] Sales order with two lines:
        // [GIVEN] Line1: "Type" = "Item", "No." = "ITEM", "Line Amount" = 1100
        CreateSalesOrder(SalesHeader, SalesLine, '', LibrarySales.CreateCustomerNo);
        // [GIVEN] Line2: "Type" = "", "No." = "", "Description" = "TEST"
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, LibraryInventory.CreateItemNo, 0);
        SalesLine2.Validate(Type, SalesLine2.Type::" ");
        SalesLine2.Validate(Description, LibraryUtility.GenerateGUID);
        SalesLine2.Modify(true);
        // [GIVEN] Set Invoice Discount Amount = 100
        SetSalesHeaderInvoiceDiscountAmount(SalesHeader, Round(SalesLine.Amount / 10));
        SalesLine.Find;
        // [GIVEN] Post the order
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Print the posted sales invoice (REP 206 "Sales - Invoice")
        RunSalesInvoiceReport(PostedDocNo, false, false, false, 0);

        // [THEN] Total section includes:
        // [THEN] Subtotal = 1100
        // [THEN] Invoice Discount Amount = 100
        // [THEN] Amount Excluding VAT = 1000
        // [THEN] VAT Amount = 200
        // [THEN] Amount Including VAT = 1200
        VerifySalesInvoiceTotalsWithDiscount(SalesLine, 'AV', 105);
    end;

    [Test]
    [HandlerFunctions('StandardSalesOrderConfRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesOrderConfExternalDocumentNoIsPrinted()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UI] [Order] [Confirmation]
        // [SCENARIO 225794] "External Document No." is shown with its caption when report "Standard Sales - Order Conf." is printed for Sales Order
        Initialize;

        // [GIVEN] Sales Order with "External Document No." = "XXX"
        MockSalesOrderWithExternalDocumentNo(SalesHeader);

        // [WHEN] Export report "Standard Sales - Order Conf." to XML file
        RunStandardSalesOrderConfirmationReport(SalesHeader."No.");
        LibraryReportDataset.LoadDataSetFile;

        // [THEN] Value "XXX" is displayed under Tag <ExtDocNo_SalesHeader> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('ExtDocNo_SalesHeader', SalesHeader."External Document No.");

        // [THEN] Value "External Document No." is displayed under Tag <ExtDocNo_SalesHeader_Lbl> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists(
          'ExtDocNo_SalesHeader_Lbl', SalesHeader.FieldCaption("External Document No."));
    end;

    [Test]
    [HandlerFunctions('OrderConfirmationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OrderConfirmationExternalDocumentNoIsPrinted()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UI] [Order] [Confirmation]
        // [SCENARIO 225794] "External Document No." is shown with its caption when report "Order Confirmation" is printed for Sales Order
        Initialize;

        // [GIVEN] Sales Order with "External Document No." = "XXX"
        MockSalesOrderWithExternalDocumentNo(SalesHeader);

        // [WHEN] Export report "Order Confirmation" to XML file
        RunOrderConfirmationReport(SalesHeader."No.");
        LibraryReportDataset.LoadDataSetFile;

        // [THEN] Value "XXX" is displayed under Tag <YourReference_SalesHeader> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('YourReference_SalesHeader', SalesHeader."External Document No.");

        // [THEN] Value "External Document No." is displayed under Tag <ReferenceText> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('ReferenceText', SalesHeader.FieldCaption("External Document No."));
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceExternalDocumentNoIsPrinted()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 233670] Value of "External Document No." is shown with its caption when report "Standard Sales - Invoce" is printed for posted Sales Invoice with "External Document No."
        Initialize;

        // [GIVEN] Posted Sales Invoice with "External Document No." = "ExtDocNo001"
        MockSalesInvoiceHeaderWithExternalDocumentNo(SalesInvoiceHeader);

        // [WHEN] Export report "Standard Sales - Invoice" to XML file
        RunStandardSalesInvoiceReport(SalesInvoiceHeader."No.");
        LibraryReportDataset.LoadDataSetFile;

        // [THEN] Value "ExtDocNo001" is displayed under tag <LeftHeaderValue> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('LeftHeaderValue', SalesInvoiceHeader."External Document No.");

        // [THEN] Value "External Document No." is displayed under tag <LeftHeaderName> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('LeftHeaderName', SalesInvoiceHeader.FieldCaption("External Document No."));
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceExternalDocumentNoIsNotPrinted()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 233670] Value of "External Document No." is not shown with its caption when report "Standard Sales - Invoce" is printed for posted Sales Invoice without "External Document No."
        Initialize;

        // [GIVEN] Posted Sales Invoice without "External Document No."
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID;
        SalesInvoiceHeader.Insert();

        // [WHEN] Export report "Standard Sales - Invoice" to XML file
        RunStandardSalesInvoiceReport(SalesInvoiceHeader."No.");
        LibraryReportDataset.LoadDataSetFile;

        // [THEN] Value "External Document No." is not displayed under tag <LeftHeaderName> in export XML file
        LibraryReportDataset.AssertElementTagWithValueNotExist(
          'LeftHeaderName', SalesInvoiceHeader.FieldCaption("External Document No."));
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AccumulateRoundedVATBaseLCYtInSalesInvoiceRepForDocHavingTwoLinesFCY()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        ExchangeRate: Decimal;
        UnitPrice: array[2] of Decimal;
        VATPercent: array[2] of Decimal;
        VATProdPostingGroup: array[2] of Code[20];
    begin
        // [FEATURE] [Rounding]
        // [SCENARIO 235281] VAT Base LCY on "Sales - Invoice" report must accumulate remainig amounts from previous lines in FCY having different "VAT Prod. Posting Group"
        Initialize;

        // [GIVEN] "Print VAT specification in LCY" in the "General Ledger Setup" = True
        UpdateGeneralLedgerSetup(true);

        // [GIVEN] Currency "CAD" with "Echange Rate Amount" = 0.881834
        ExchangeRate := 0.881834; // magic number is needed for correct rounding
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, ExchangeRate, ExchangeRate);

        // [GIVEN] VAT Posting Setup with "VAT Bus. Posting Group" = "BPG1", "VAT Prod. Posting Group" = "VAT25", "VAT Identifier" = "VAT25", "VAT %" = 25
        VATPercent[1] := LibraryRandom.RandIntInRange(50, 60);
        CreateVATPostingGroup(VATPostingSetup, VATPercent[1]);
        VATProdPostingGroup[1] := VATPostingSetup."VAT Prod. Posting Group";

        // [GIVEN] VAT Posting Setup with "VAT Bus. Posting Group" = "BPG1", "VAT Prod. Posting Group" = "VAT10", "VAT Identifier" = "VAT10", "VAT %" = 10
        VATPercent[2] := LibraryRandom.RandIntInRange(40, 49);
        CreateVATPostingSetupWithAccountsForBusPostingGroup(VATPostingSetup, VATPostingSetup."VAT Bus. Posting Group", VATPercent[2]);
        VATProdPostingGroup[2] := VATPostingSetup."VAT Prod. Posting Group";

        // [GIVEN] Posted Sales Invoice "PSI001" in "CAD"
        CreateSalesHeader(
          SalesHeader, CurrencyCode, LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));

        // [GIVEN] The first Line has "VAT Prod. Posting Group" = VAT25, Amount = 2650.76
        // [GIVEN] The first VAT Entry has
        // [GIVEN] "VAT Base" = 3005.96 (ROUND(2650.76/0.881834,2))
        // [GIVEN] Amount = 751,49
        UnitPrice[1] := 2650.76; // magic numbers are needed for correct rounding
        CreateSalesLineWithVAT(
          SalesHeader, SalesLine, CreateItemWithVATProdPostingGroup(VATProdPostingGroup[1]), UnitPrice[1]);

        // [GIVEN] The second Line has "VAT Prod. Posting Group" = VAT10, Amount = 180.78
        // [GIVEN] The second VAT Entry has
        // [GIVEN] "VAT Base" = 205.01 ((ROUND(180.78/0.881834 + remaining amount from previous line,2)))
        // [GIVEN] Amount = 20,50
        UnitPrice[2] := 180.78;
        CreateSalesLineWithVAT(
          SalesHeader, SalesLine, CreateItemWithVATProdPostingGroup(VATProdPostingGroup[2]), UnitPrice[2]);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Pring "Sales - Invoice" for "PSI001"
        RunSalesInvoiceReport(DocumentNo, false, false, false, 1);

        // [THEN] The first "VAT Base LCY" = 205.01
        // [THEN] The first "VAT Amount LCY" = 20,50
        // [THEN] The first "VAT %" = 10
        // [THEN] The first "VAT Identifier" = "VAT10"
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.MoveToRow(LibraryReportDataset.RowCount - 1);
        FindVATEntry(VATEntry, DocumentNo, WorkDate, VATProdPostingGroup[2]);
        VerifyVATSpecificationLCYForSalesInvoice(VATEntry, VATPercent[2]);

        // [THEN] The second "VAT Base LCY" = 3005.96
        // [THEN] The second "VAT Amount LCY" = 751,49
        // [THEN] The second "VAT %" = 25
        // [THEN] The second "VAT Identifier" = "VAT25"
        LibraryReportDataset.GetLastRow;
        FindVATEntry(VATEntry, DocumentNo, WorkDate, VATProdPostingGroup[1]);
        VerifyVATSpecificationLCYForSalesInvoice(VATEntry, VATPercent[1]);
    end;

    [Test]
    [HandlerFunctions('SalesQuoteADChangeRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteArchiveDocFlagStateIsSavedAfterRun()
    var
        ArchiveDocValue: Text;
    begin
        // [FEATURE] [Sales Quote]
        // [SCENARIO 256827] "Archive Document" flag state is saved when Stan runs the "Sales - Quote" report for the second time, i.e. "Saved setting" feature works for this flag.
        Initialize;

        // [GIVEN] Report "Sales - Quote" was run for the first time, "Archive Document" flag state was changed before the report was run.
        Commit();
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Sales - Quote");
        ArchiveDocValue := LibraryVariableStorage.DequeueText;

        // [WHEN] Report "Sales - Quote" is run for the second time.
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Sales - Quote");

        // [THEN] "Archive Document" flag state is saved after the first run.
        Assert.AreEqual(
          ArchiveDocValue, LibraryVariableStorage.DequeueText, 'Unexpected value for ArchiveDocument field');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('OrderConfirmationADChangeRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OrderConfirmationArchiveDocFlagStateIsSavedAfterRun()
    var
        ArchiveDocValue: Text;
    begin
        // [FEATURE] [Sales] [Order] [Order Confirmation]
        // [SCENARIO 256827] "Archive Document" flag state is saved when Stan runs the "Order Confirmation" report for the second time, i.e. "Saved setting" feature works for this flag.
        Initialize;

        // [GIVEN] Report "Order Confirmation" was run for the first time, "Archive Document" flag state was changed before the report was run.
        Commit();
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Order Confirmation");
        ArchiveDocValue := LibraryVariableStorage.DequeueText;

        // [WHEN] Report "Order Confirmation" is run for the second time.
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Order Confirmation");

        // [THEN] "Archive Document" flag state is saved after the first run.
        Assert.AreEqual(
          ArchiveDocValue, LibraryVariableStorage.DequeueText, 'Unexpected value for ArchiveDocument field');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('BlanketSalesOrderADChangeRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderArchiveDocFlagStateIsSavedAfterRun()
    var
        ArchiveDocValue: Text;
    begin
        // [FEATURE] [Blanket Sales Order]
        // [SCENARIO 256827] "Archive Document" flag state is saved when Stan runs the "Blanket Sales Order" report for the second time, i.e. "Saved setting" feature works for this flag.
        Initialize;

        // [GIVEN] Report "Blanket Sales Order" was run for the first time, "Archive Document" flag state was changed before the report was run.
        Commit();
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Blanket Sales Order");
        ArchiveDocValue := LibraryVariableStorage.DequeueText;

        // [WHEN] Report "Blanket Sales Order" is run for the second time.
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Blanket Sales Order");

        // [THEN] "Archive Document" flag state is saved after the first run.
        Assert.AreEqual(
          ArchiveDocValue, LibraryVariableStorage.DequeueText, 'Unexpected value for ArchiveDocument field');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('StdSalesDraftInvoiceADChangeRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesDraftInvoiceArchiveDocFlagStateIsSavedAfterRun()
    var
        ArchiveDocValue: Text;
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 256827] "Archive Document" flag state is saved when Stan runs the "Standard Sales - Draft Invoice" report for the second time, i.e. "Saved setting" feature works for this flag.
        Initialize;

        // [GIVEN] Report "Standard Sales - Draft Invoice" was run for the first time, "Archive Document" flag state was changed before the report was run.
        Commit();
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Standard Sales - Draft Invoice");
        ArchiveDocValue := LibraryVariableStorage.DequeueText;

        // [WHEN] Report "Standard Sales - Draft Invoice" is run for the second time.
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Standard Sales - Draft Invoice");

        // [THEN] "Archive Document" flag state is saved after the first run.
        Assert.AreEqual(
          ArchiveDocValue, LibraryVariableStorage.DequeueText, 'Unexpected value for ArchiveDocument field');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('StdSalesQuoteADChangeRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesQuoteArchiveDocFlagStateIsSavedAfterRun()
    var
        ArchiveDocValue: Text;
    begin
        // [FEATURE] [Sales Quote]
        // [SCENARIO 256827] "Archive Document" flag state is saved when Stan runs the "Standard Sales - Quote" report for the second time, i.e. "Saved setting" feature works for this flag.
        Initialize;

        // [GIVEN] Report "Standard Sales - Quote" was run for the first time, "Archive Document" flag state was changed before the report was run.
        Commit();
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Standard Sales - Quote");
        ArchiveDocValue := LibraryVariableStorage.DequeueText;

        // [WHEN] Report "Standard Sales - Quote" is run for the second time.
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Standard Sales - Quote");

        // [THEN] "Archive Document" flag state is saved after the first run.
        Assert.AreEqual(
          ArchiveDocValue, LibraryVariableStorage.DequeueText, 'Unexpected value for ArchiveDocument field');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('StdSalesOrderConfADChangeRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesOrderConfArchiveDocFlagStateIsSavedAfterRun()
    var
        ArchiveDocValue: Text;
    begin
        // [FEATURE] [Order Confirmation]
        // [SCENARIO 256827] "Archive Document" flag state is saved when Stan runs the "Standard Sales - Order Conf." report for the second time, i.e. "Saved setting" feature works for this flag.
        Initialize;

        // [GIVEN] Report "Standard Sales - Order Conf." was run for the first time, "Archive Document" flag state was changed before the report was run.
        Commit();
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Standard Sales - Order Conf.");
        ArchiveDocValue := LibraryVariableStorage.DequeueText;

        // [WHEN] Report "Standard Sales - Order Conf." is run for the second time.
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Standard Sales - Order Conf.");

        // [THEN] "Archive Document" flag state is saved after the first run.
        Assert.AreEqual(
          ArchiveDocValue, LibraryVariableStorage.DequeueText, 'Unexpected value for ArchiveDocument field');

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('DraftSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DraftSalesInvoiceWithExternalDocNo()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 257521] External Document Number exists in report "Standard Sales - Draft Invoice" dataset.
        Initialize;

        // [GIVEN] Sales Invoice with "External Doc No.".
        CreateSalesInvoiceWithExternalDocNo(SalesHeader);
        Commit();

        // [WHEN] Run report "Standard Sales - Draft Invoice".
        SalesHeader.SetRecFilter;
        REPORT.Run(REPORT::"Standard Sales - Draft Invoice", true, false, SalesHeader);

        // [THEN] Report dataset contains "External Doc No.".
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('DocumentNo', SalesHeader."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow, '');
        LibraryReportDataset.AssertCurrentRowValueEquals('ExternalDocumentNo', SalesHeader."External Document No.");
    end;

    [Test]
    [HandlerFunctions('DraftSalesInvoiceExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintExternalDocNoOnDraftSalesInvoiceReport()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 257521] External Document Number is printed in report "Standard Sales - Draft Invoice".
        Initialize;
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);
        SetRDLCReportLayout(REPORT::"Standard Sales - Draft Invoice");

        // [GIVEN] Sales Invoice with "External Doc No.".
        CreateSalesInvoiceWithExternalDocNo(SalesHeader);
        Commit();

        // [WHEN] Print report "Standard Sales - Draft Invoice" as Excel.
        SalesHeader.SetRecFilter;
        REPORT.Run(REPORT::"Standard Sales - Draft Invoice", true, false, SalesHeader);

        // [THEN] Saved Excel file contains "External Doc No.".
        LibraryReportValidation.OpenExcelFile;
        LibraryReportValidation.VerifyCellValue(21, 17, SalesHeader."External Document No.");
    end;

    [Test]
    [HandlerFunctions('StdSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ShipmentsExistsWhenSaveAsXMLStandardSalesInvoiceReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [SCENARIO 257602] "Quantity_ShipmentLine" xml node exists when "Standard Sales - Invoice" report saves as XML

        Initialize;

        // [GIVEN] Post shipment from Order
        PostShipReceiveOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);

        // [GIVEN] Post Invoice from Order
        SalesInvoiceHeader.SetRange("No.", LibrarySales.PostSalesDocument(SalesHeader, false, true));
        SalesInvoiceHeader.FindFirst;
        Commit();

        // [WHEN] Run "Save as Xml" for "Standard Sales - Invoice" with option "Show Shipments"
        SalesInvoiceHeader.SetRecFilter;
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] "Quantity_ShipmentLine" xml node exists in exported file
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('DocumentNo', SalesInvoiceHeader."No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'DocumentNo', SalesInvoiceHeader."No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_ShipmentLine', SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('StdSalesCrMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReceiptsExistsWhenSaveAsXMLStandardSalesCrMemoReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [SCENARIO 257602] "Quantity_ShipmentLine" xml node exists when "Standard Sales - Credit Memo" Report saves as XML

        Initialize;

        // [GIVEN] Post receive from Return Order
        PostShipReceiveOrder(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order");

        // [GIVEN] Post Cr. Memo from Return Order
        SalesCrMemoHeader.SetRange("No.", LibrarySales.PostSalesDocument(SalesHeader, false, true));
        SalesCrMemoHeader.FindFirst;
        Commit();

        // [WHEN] Run "Save as Xml" for "Standard Sales - Credit Memo" with option "Show Shipments"
        SalesCrMemoHeader.SetRecFilter;
        REPORT.Run(REPORT::"Standard Sales - Credit Memo", true, false, SalesCrMemoHeader);

        // [THEN] "Quantity_ShipmentLine" xml node exists in exported file
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('DocumentNo', SalesCrMemoHeader."No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'DocumentNo', SalesCrMemoHeader."No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_ShipmentLine', SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('CustomerDetailTrialBalanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetailTrialBalanceExtDocNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Customer - Detail Trial Bal.]
        // [SCENARIO 262729] External Document No. is included in report Customer - Detail Trial Bal.

        // [GIVEN] Create and Post General Journal Line with External Document No.
        Initialize;
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateCustomer, '', LibraryRandom.RandDec(100, 2), WorkDate);
        GenJournalLine.Validate("External Document No.", CopyStr(LibraryUtility.GenerateRandomXMLText(35), 1, 35));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Generate the Customer Detail Trial Balance Report.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");
        REPORT.Run(REPORT::"Customer - Detail Trial Bal.");

        // [THEN] Verify External Document No. on the Customer Detail Trial Balance Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('DocNo_CustLedgEntry', GenJournalLine."Document No.");
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('ExtDocNo_CustLedgEntry', GenJournalLine."External Document No.");
    end;

    [Test]
    [HandlerFunctions('StdSalesQuoteExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesQuoteDoesNotHaveEmptyPage()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Standard] [Quote]
        // [SCENARIO 266011] "Standard Sales - Quote" report do not have extra blank pages.
        Initialize;
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);
        SetRDLCReportLayout(REPORT::"Standard Sales - Quote");

        // [GIVEN] Create Sales Quote with one line.
        CreateSalesQuoteWithLine(SalesHeader, SalesLine, CreateCustomer);

        // [WHEN] Run report "Standard Sales - Quote".
        Commit();
        SalesHeader.SetRecFilter;
        REPORT.Run(REPORT::"Standard Sales - Quote", true, false, SalesHeader);

        // [THEN] Saved Excel file has only one sheet.
        VerifyNoOfWorksheetsInExcel(1);
    end;

    [Test]
    [HandlerFunctions('StdSalesDraftInvoiceExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesDraftInvoiceDoesNotHaveEmptyPage()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Standard] [Draft] [Invoice]
        // [SCENARIO 266011] "Standard Sales - Draft Invoice" report do not have extra blank pages.
        Initialize;
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);
        SetRDLCReportLayout(REPORT::"Standard Sales - Draft Invoice");

        // [GIVEN] Create Sales Invoice with one line.
        CreateSalesInvoiceWithLine(SalesHeader, SalesLine, CreateCustomer);

        // [WHEN] Run report "Standard Sales - Draft Invoice".
        Commit();
        SalesHeader.SetRecFilter;
        REPORT.Run(REPORT::"Standard Sales - Draft Invoice", true, false, SalesHeader);

        // [THEN] Saved Excel file has only one sheet.
        VerifyNoOfWorksheetsInExcel(1);
    end;

    [Test]
    [HandlerFunctions('StdSalesInvoiceExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesInvoiceDoesNotHaveEmptyPage()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Standard] [Invoice]
        // [SCENARIO 266011] "Standard Sales - Invoice" report do not have extra blank pages.
        Initialize;
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);
        SetRDLCReportLayout(REPORT::"Standard Sales - Invoice");

        // [GIVEN] Create Sales Invoice with one line.
        CreateSalesInvoiceWithLine(SalesHeader, SalesLine, CreateCustomer);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Run report "Standard Sales - Invoice".
        Commit();
        SalesInvoiceHeader.SetRecFilter;
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Saved Excel file has only one sheet.
        LibraryReportValidation.OpenExcelFile;
        Assert.AreEqual(1, LibraryReportValidation.CountWorksheets, ExcelCountWorksheetsErr);
        // [THEN] Report title is 'Invoice'
        LibraryReportValidation.VerifyCellValue(7, 24, InvoiceTxt);
    end;

    [Test]
    [HandlerFunctions('StdSalesCreditMemoExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesCreditMemoDoesNotHaveEmptyPage()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [Standard] [Credit Memo]
        // [SCENARIO 266011] "Standard Sales - Credit Memo" report do not have extra blank pages.
        Initialize;
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);
        SetRDLCReportLayout(REPORT::"Standard Sales - Credit Memo");

        // [GIVEN] Create Sales Quote with one line.
        CreateSalesCreditMemoWithLine(SalesHeader, SalesLine, CreateCustomer);
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Run report "Standard Sales - Quote".
        Commit();
        SalesCrMemoHeader.SetRecFilter;
        REPORT.Run(REPORT::"Standard Sales - Credit Memo", true, false, SalesCrMemoHeader);

        // [THEN] Saved Excel file has only one sheet.
        VerifyNoOfWorksheetsInExcel(1);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceDocumentCaption()
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Report Caption]
        Initialize;
        // [GIVEN] Posted sales invoice
        CreateAndSetupSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);

        // [WHEN] Print Sales Invoice
        RunSalesInvoiceReport(DocumentNo, false, false, false, 0);

        // [THEN] Report title is 'Sales - Invoice'
        LibraryReportDataset.LoadDataSetFile;
        Assert.IsTrue(LibraryReportDataset.GetNextRow, 'Cannot find first row.');
        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentCaptionCopyText', StrSubstNo(SalesInvoiceTxt, ''));
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceDocumentCustomCaption()
    var
        SalesHeader: Record "Sales Header";
        ReportCaptionSubscriber: Codeunit "Report Caption Subscriber";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Report Caption]
        Initialize;
        // [GIVEN] Posted sales invoice
        CreateAndSetupSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);
        // [GIVEN] Redefined report title as 'Sales - Tax Invoice'
        ReportCaptionSubscriber.SetCaption(SalesTaxInvoiceTxt);
        BindSubscription(ReportCaptionSubscriber);

        // [WHEN] Print Sales Invoice
        RunSalesInvoiceReport(DocumentNo, false, false, false, 0);

        // [THEN] Report title is 'Sales - Tax Invoice'
        LibraryReportDataset.LoadDataSetFile;
        Assert.IsTrue(LibraryReportDataset.GetNextRow, 'Cannot find first row.');
        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentCaptionCopyText', StrSubstNo(SalesTaxInvoiceTxt, ''));
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesPrepmtInvoiceDocumentCaption()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Report Caption] [Prepayment]
        Initialize;
        // [GIVEN] Posted sales prepayment invoice
        CreateAndSetupSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader."Prepayment Invoice" := true;
        SalesInvoiceHeader.Modify();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);

        // [WHEN] Print Sales Invoice
        RunSalesInvoiceReport(DocumentNo, false, false, false, 0);

        // [THEN] Report title is 'Sales - Prepayment Invoice'
        LibraryReportDataset.LoadDataSetFile;
        Assert.IsTrue(LibraryReportDataset.GetNextRow, 'Cannot find first row.');
        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentCaptionCopyText', StrSubstNo(SalesPrepmtInvoiceTxt, ''));
    end;

    [Test]
    [HandlerFunctions('StdSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesInvoiceDocumentCustomCaption()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReportCaptionSubscriber: Codeunit "Report Caption Subscriber";
    begin
        // [FEATURE] [Invoice] [Report Caption]
        Initialize;
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);
        SetRDLCReportLayout(REPORT::"Standard Sales - Invoice");

        // [GIVEN] Create Sales Invoice with one line.
        CreateSalesInvoiceWithLine(SalesHeader, SalesLine, CreateCustomer);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        // [GIVEN] Redefined report title as 'Sales - Tax Invoice'
        ReportCaptionSubscriber.SetCaption(TaxInvoiceTxt);
        BindSubscription(ReportCaptionSubscriber);

        // [WHEN] Run report "Standard Sales - Invoice".
        Commit();
        SalesInvoiceHeader.SetRecFilter;
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Report title is 'Invoice'
        LibraryReportDataset.LoadDataSetFile;
        Assert.IsTrue(LibraryReportDataset.GetNextRow, 'Cannot find first row.');
        LibraryReportDataset.AssertCurrentRowValueEquals('DocumentTitle_Lbl', TaxInvoiceTxt);
    end;

    [Test]
    [HandlerFunctions('DraftSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesDraftInvoicePmtMethodTranslation()
    var
        PaymentMethod: Record "Payment Method";
        PaymentMethodTranslation: Record "Payment Method Translation";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Invoice] [Payment Method Translation]
        // [SCENARIO 278606] Payment Method is Translated in report "Standard Sales - Draft Invoice"
        Initialize;

        // [GIVEN] Payment Method "CASH" with Description
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        // [GIVEN] Payment Method Translation with Language Code "DEU" and Description
        PaymentMethodTranslation.Get(PaymentMethod.Code, LibraryERM.CreatePaymentMethodTranslation(PaymentMethod.Code));
        ModifyLanguageWindowsLanguageID(PaymentMethodTranslation."Language Code", GlobalLanguage);

        // [GIVEN] Sales Invoice with Payment Method "CASH" for Customer with Language Code = "DEU"
        CreateSalesDocumentWithPaymentMethod(
          SalesHeader, SalesHeader."Document Type"::Invoice, PaymentMethod.Code,
          CreateCustomerWithLanguageCode(PaymentMethodTranslation."Language Code"));
        SalesHeader.SetRecFilter;
        Commit();

        // [WHEN] Run report "Standard Sales - Draft Invoice"
        REPORT.Run(REPORT::"Standard Sales - Draft Invoice", true, false, SalesHeader);

        // [THEN] Report Dataset has Payment Method Translation Description under tag '<PaymentMethodDescription>'
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementTagWithValueExists('PaymentMethodDescription', PaymentMethodTranslation.Description);
    end;

    [Test]
    [HandlerFunctions('StandardSalesQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesQuotePmtMethodTranslation()
    var
        PaymentMethod: Record "Payment Method";
        PaymentMethodTranslation: Record "Payment Method Translation";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Quote] [Payment Method Translation]
        // [SCENARIO 278606] Payment Method is Translated in report "Standard Sales - Quote"
        Initialize;

        // [GIVEN] Payment Method "CASH" with Description
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        // [GIVEN] Payment Method Translation with Language Code "DEU" and Description
        PaymentMethodTranslation.Get(PaymentMethod.Code, LibraryERM.CreatePaymentMethodTranslation(PaymentMethod.Code));
        ModifyLanguageWindowsLanguageID(PaymentMethodTranslation."Language Code", GlobalLanguage);

        // [GIVEN] Sales Quote with Payment Method "CASH" for Customer with Language Code = "DEU"
        CreateSalesDocumentWithPaymentMethod(
          SalesHeader, SalesHeader."Document Type"::Quote, PaymentMethod.Code,
          CreateCustomerWithLanguageCode(PaymentMethodTranslation."Language Code"));
        SalesHeader.SetRecFilter;
        Commit();

        // [WHEN] Run report "Standard Sales - Quote"
        REPORT.Run(REPORT::"Standard Sales - Quote", true, false, SalesHeader);

        // [THEN] Report Dataset has Payment Method Translation Description under tag '<PaymentMethodDescription>'
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementTagWithValueExists('PaymentMethodDescription', PaymentMethodTranslation.Description);
    end;

    [Test]
    [HandlerFunctions('StandardSalesOrderConfRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesOrderConfPmtMethodTranslation()
    var
        PaymentMethod: Record "Payment Method";
        PaymentMethodTranslation: Record "Payment Method Translation";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Order] [Payment Method Translation]
        // [SCENARIO 278606] Payment Method is Translated in report "Standard Sales - Order Conf."
        Initialize;

        // [GIVEN] Payment Method "CASH" with Description
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        // [GIVEN] Payment Method Translation with Language Code "DEU" and Description
        PaymentMethodTranslation.Get(PaymentMethod.Code, LibraryERM.CreatePaymentMethodTranslation(PaymentMethod.Code));
        ModifyLanguageWindowsLanguageID(PaymentMethodTranslation."Language Code", GlobalLanguage);

        // [GIVEN] Sales Order with Payment Method "CASH" for Customer with Language Code = "DEU"
        CreateSalesDocumentWithPaymentMethod(
          SalesHeader, SalesHeader."Document Type"::Order, PaymentMethod.Code,
          CreateCustomerWithLanguageCode(PaymentMethodTranslation."Language Code"));
        SalesHeader.SetRecFilter;
        Commit();

        // [WHEN] Run report "Standard Sales - Order Conf."
        REPORT.Run(REPORT::"Standard Sales - Order Conf.", true, false, SalesHeader);

        // [THEN] Report Dataset has Payment Method Translation Description under tag '<PaymentMethodDescription>'
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementTagWithValueExists('PaymentMethodDescription', PaymentMethodTranslation.Description);
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesInvoicePmtMethodTranslation()
    var
        PaymentMethod: Record "Payment Method";
        PaymentMethodTranslation: Record "Payment Method Translation";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Sales] [Invoice] [Payment Method Translation]
        // [SCENARIO 278606] Payment Method is Translated in report "Standard Sales - Invoice"
        Initialize;

        // [GIVEN] Payment Method "CASH" with Description
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        // [GIVEN] Payment Method Translation with Language Code "DEU" and Description
        PaymentMethodTranslation.Get(PaymentMethod.Code, LibraryERM.CreatePaymentMethodTranslation(PaymentMethod.Code));
        ModifyLanguageWindowsLanguageID(PaymentMethodTranslation."Language Code", GlobalLanguage);

        // [GIVEN] Posted Sales Invoice with Payment Method "CASH" for Customer with Language Code = "DEU"
        CreateSalesDocumentWithPaymentMethod(
          SalesHeader, SalesHeader."Document Type"::Invoice, PaymentMethod.Code,
          CreateCustomerWithLanguageCode(PaymentMethodTranslation."Language Code"));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter;

        // [WHEN] Run report "Standard Sales - Invoice"
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Report DataSet has Payment Method Translation Description under tag '<PaymentMethodDescription>'
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementTagWithValueExists('PaymentMethodDescription', PaymentMethodTranslation.Description);
    end;

    [Test]
    [HandlerFunctions('StdSalesCrMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesCrMemoPmtMethodTranslation()
    var
        PaymentMethod: Record "Payment Method";
        PaymentMethodTranslation: Record "Payment Method Translation";
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [Sales] [Credit Memo] [Payment Method Translation]
        // [SCENARIO 278606] Payment Method is Translated in report "Standard Sales - Credit Memo"
        Initialize;

        // [GIVEN] Payment Method "CASH" with Description
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        // [GIVEN] Payment Method Translation with Language Code "DEU" and Description
        PaymentMethodTranslation.Get(PaymentMethod.Code, LibraryERM.CreatePaymentMethodTranslation(PaymentMethod.Code));
        ModifyLanguageWindowsLanguageID(PaymentMethodTranslation."Language Code", GlobalLanguage);

        // [GIVEN] Posted Sales Cr. Memo with Payment Method "CASH" for Customer with Language Code = "DEU"
        CreateSalesDocumentWithPaymentMethod(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", PaymentMethod.Code,
          CreateCustomerWithLanguageCode(PaymentMethodTranslation."Language Code"));
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesCrMemoHeader.SetRecFilter;

        // [WHEN] Run report "Standard Sales - Credit Memo"
        REPORT.Run(REPORT::"Standard Sales - Credit Memo", true, false, SalesCrMemoHeader);

        // [THEN] Report DataSet has Payment Method Translation Description under tag '<PaymentMethodDescription>'
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementTagWithValueExists('PaymentMethodDescription', PaymentMethodTranslation.Description);
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceShowsVATClausesFromLines()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        VATClause: array[2] of Record "VAT Clause";
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
    begin
        // [FEATURE] [Sales] [Invoice] [VAT Clause]
        // [SCENARIO 279173] Report 1306 "Standard Sales - Invoice" shows VAT Clause information for each VAT Clause used: VAT Clause Description, VAT Clause Description 2
        Initialize;

        // [GIVEN] Three VATPostingSetup records with VAT % = 20, 10 and 0.
        // [GIVEN] Two VAT Clauses records assigned for VATPostingSetup[1] and VATPostingSetup[2]
        CreateThreeVATPostingSetupsWithTwoVATClauses(VATPostingSetup, VATClause);

        // [GIVEN] Sales Invoice with 3 lines where Line1 has VATPostingSetup[1], Line2 has VATPostingSetup[2], Line3 has VATPostingSetup[3]
        CreateSalesInvoiceWithThreeLinesWithVATBusPostingSetup(SalesHeader, VATPostingSetup);

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter;

        // [WHEN] Run report "Standard Sales - Invoice" for Posted Sales Invoice
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Report DataSet contains VAT Clause fields: "VAT Identifier","VAT Clause Description", "VAT Clause Description 2" for each VAT Clause used
        VerifySalesInvoiceMultipleVATClausesPrinted(VATPostingSetup, VATClause);
    end;

    [Test]
    [HandlerFunctions('CustomerDetailTrialBalanceExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetailTrialBalanceCorrOfRemainingAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        CustNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Customer - Detail Trial Bal.]
        // [SCENARIO 280971] "Correction of remaining amount" does not affect totals in Customer - Detail Trial Bal. report

        Initialize;

        // [GIVEN] Currency with exchange rate 1 to 0.33333
        CurrencyCode := CreateCurrencyWithFixedExchRates(0.33333);

        // [GIVEN] Post two invoices with currency and amount = 1 (LCY Amount = 0.33)
        CustNo := LibrarySales.CreateCustomerNo;
        for i := 1 to 2 do
            CreatePostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, CustNo, CurrencyCode, 1, WorkDate);

        // [GIVEN] Post payment with currency and amount = 2 (LCY Amount = 0.67)
        CreatePostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, CustNo, CurrencyCode, -2, WorkDate);

        // [GIVEN] Applied payment to both invoices
        ApplyPaymentToAllOpenInvoices(GenJournalLine."Document No.", CustNo);

        // [GIVEN] Post invoice with currency and amount = 400 (LCY Amount = 133.33)
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CustNo, CurrencyCode, LibraryRandom.RandDec(100, 2), WorkDate);

        // [WHEN] Generate the Customer Detail Trial Balance Report.
        RunDtldCustTrialBalanceReportWithDateFilter(GenJournalLine."Account No.");

        // [THEN] Verify start balance is zero and customer balance is 133.33
        LibraryReportValidation.OpenExcelFile;
        LibraryReportValidation.VerifyCellValue(27, 5, Format(GenJournalLine."Amount (LCY)", 0, 9));
        LibraryReportValidation.VerifyCellValue(27, 9, Format(GenJournalLine."Amount (LCY)", 0, 9));
    end;

    [Test]
    [HandlerFunctions('DraftSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesDraftInvoiceShowsVATClausesFromLines()
    var
        SalesHeader: Record "Sales Header";
        VATClause: array[2] of Record "VAT Clause";
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
    begin
        // [FEATURE] [Sales] [Invoice] [VAT Clause]
        // [SCENARIO 280820] Report 1303 "Standard Sales - Draft Invoice" shows VAT Clause information for each VAT Clause used: VAT Clause Description, VAT Clause Description 2
        Initialize;

        // [GIVEN] Three VATPostingSetup records with VAT % = 20, 10 and 0.
        // [GIVEN] Two VAT Clauses records assigned for VATPostingSetup[1] and VATPostingSetup[2]
        CreateThreeVATPostingSetupsWithTwoVATClauses(VATPostingSetup, VATClause);

        // [GIVEN] Sales Invoice with 3 lines where Line1 has VATPostingSetup[1], Line2 has VATPostingSetup[2], Line3 has VATPostingSetup[3]
        CreateSalesInvoiceWithThreeLinesWithVATBusPostingSetup(SalesHeader, VATPostingSetup);
        SalesHeader.SetRecFilter;
        Commit();

        // [WHEN] Run report "Standard Sales - Draft Invoice" for Sales Invoice
        REPORT.Run(REPORT::"Standard Sales - Draft Invoice", true, false, SalesHeader);

        // [THEN] Report DataSet contains VAT Clause fields: "VAT Identifier","VAT Clause Description", "VAT Clause Description 2" for each VAT Clause used
        VerifySalesInvoiceMultipleVATClausesPrinted(VATPostingSetup, VATClause);
    end;

    [Test]
    [HandlerFunctions('CustomerOrderSummaryExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOrderSummaryMultipleCurrencies()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        CurrencyCode: array[2] of Code[10];
        Amount: array[2] of Decimal;
        I: Integer;
    begin
        // [FEATURE] [Customer Order Summary]
        // [SCENARIO 286863] Customer Order Summary splits lines for orders in different currencies
        Initialize;

        // [GIVEN] Created Customer
        CustomerNo := CreateCustomer;

        // [GIVEN] Currency "CUR01" with Exchange Rate created
        // [GIVEN] Sales Order "SO01" for Customer with Amount = 100 in Currency "CUR01"
        // [GIVEN] Currency "CUR02" with Exchange Rate created
        // [GIVEN] Sales Order "SO02" for Customer with Amount = 200 in Currency "CUR02"
        for I := 1 to ArrayLen(CurrencyCode) do begin
            CurrencyCode[I] := CreateCurrency;
            CreateSalesOrder(SalesHeader, SalesLine, CurrencyCode[I], CustomerNo);
            Amount[I] := SalesLine."Line Amount";
        end;

        // [WHEN] Run Report "Customer Order Summary"
        LibraryReportValidation.SetFileName(CustomerNo);
        RunCustOrderSummaryReport(CustomerNo, false);

        // [THEN] Amount = 100 for Currency "CUR01"
        // [THEN] Amount = 200 for Currency "CUR02"
        VerifyMultipleCurrencyAmountsOnCustomerOrderSummaryReport(CurrencyCode, Amount);
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceHasPhoneAndFaxInDataset()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 299029] Report 1306 "Standard Sales - Invoice" has Phone and Fax of Sell-to Customer in dataset
        Initialize;

        // [GIVEN] A Customer with a phone number and a fax number
        CreateCustomerWithPhoneAndFaxNo(Customer);

        // [GIVEN] A Sales Invoice for this Customer
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter;

        // [WHEN] Run report "Standard Sales - Invoice" for Posted Sales Invoice
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Report DataSet contains Customer."Phone No."
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementTagWithValueExists('SellToPhoneNo', Customer."Phone No.");

        // [THEN] Report DataSet contains Customer."Fax No."
        LibraryReportDataset.AssertElementTagWithValueExists('SellToFaxNo', Customer."Fax No.");
    end;

    [Test]
    [HandlerFunctions('StandardSalesOrderConfRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesOrderHasPhoneAndFaxInDataset()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 299029] Report 1305 "Standard Sales - Order Conf." has Phone and Fax of Sell-to Customer in dataset
        Initialize;

        // [GIVEN] A Customer with a phone number and a fax number
        CreateCustomerWithPhoneAndFaxNo(Customer);

        // [GIVEN] A Sales Order for this Customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.SetRecFilter;

        Commit();

        // [WHEN] Run report "Standard Sales - Order Conf." for Sales Order
        REPORT.Run(REPORT::"Standard Sales - Order Conf.", true, false, SalesHeader);

        // [THEN] Report DataSet contains Customer."Phone No."
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementTagWithValueExists('SellToPhoneNo', Customer."Phone No.");

        // [THEN] Report DataSet contains Customer."Fax No."
        LibraryReportDataset.AssertElementTagWithValueExists('SellToFaxNo', Customer."Fax No.");
    end;

    [Test]
    [HandlerFunctions('StandardSalesOrderConfRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesOrderConfYourReference()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UI] [Order] [Confirmation]
        // [SCENARIO 299822] "Your Reference" is in dataset of report "Standard Sales - Order Conf."
        Initialize;

        // [GIVEN] Sales Order with "Your Reference" = "XXX"
        MockSalesOrderWithExternalDocumentNo(SalesHeader);
        SalesHeader."Your Reference" := LibraryUtility.GenerateGUID;
        SalesHeader.Modify();

        // [WHEN] Export report "Standard Sales - Order Conf." to XML file
        RunStandardSalesOrderConfirmationReport(SalesHeader."No.");
        LibraryReportDataset.LoadDataSetFile;

        // [THEN] Value "XXX" is displayed under Tag <YourReference> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('YourReference', SalesHeader."Your Reference");

        // [THEN] Value "External Document No." is displayed under Tag <YourReference_Lbl> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('YourReference_Lbl', SalesHeader.FieldCaption("Your Reference"));
    end;

    [Test]
    [HandlerFunctions('StdSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesInvoicePaymentTerms()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PaymentTerms: Record "Payment Terms";
        PostedSalesInvoiceNo: Code[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 304263] Report "Standard Sales - Invoice" shows Payment Terms Desription.
        Initialize;

        // [GIVEN] Using RDLC.
        SetRDLCReportLayout(REPORT::"Standard Sales - Invoice");

        // [GIVEN] Posted Sales Invoice with Payment Terms with Description "X".
        LibrarySales.CreateSalesInvoice(SalesHeader);

        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms.Validate(Description, LibraryUtility.GenerateGUID);
        PaymentTerms.Modify(true);
        SalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        SalesHeader.Modify(true);

        PostedSalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [WHEN] Report Standard Sales - Invoice is run for Posted Sales Invoice.
        SalesInvoiceHeader.Get(PostedSalesInvoiceNo);
        SalesInvoiceHeader.SetRecFilter;
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Payment Terms Description "X" is shown in report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementTagWithValueExists('PaymentTermsDescription', PaymentTerms.Description);
    end;

    [Test]
    [HandlerFunctions('StdSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesInvoiceShippingMethod()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ShipmentMethod: Record "Shipment Method";
        PostedSalesInvoiceNo: Code[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 304263] Report "Standard Sales - Invoice" shows Shipment Method Desription.
        Initialize;

        // [GIVEN] Using RDLC.
        SetRDLCReportLayout(REPORT::"Standard Sales - Invoice");

        // [GIVEN] Posted Sales Invoice with Shipment Method with Description "X".
        LibrarySales.CreateSalesInvoice(SalesHeader);

        CreateShipmentMethod(ShipmentMethod);
        SalesHeader.Validate("Shipment Method Code", ShipmentMethod.Code);
        SalesHeader.Modify(true);

        PostedSalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [WHEN] Report Standard Sales - Invoice is run for Posted Sales Invoice.
        SalesInvoiceHeader.Get(PostedSalesInvoiceNo);
        SalesInvoiceHeader.SetRecFilter;
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Shipment Method Description "X" is shown in report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementTagWithValueExists('ShipmentMethodDescription', ShipmentMethod.Description);
    end;

    [Test]
    [HandlerFunctions('CustomerOrderSummaryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerOrderSummaryForSalesLineWithDimension()
    var
        Customer: Record Customer;
        DimensionValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Dimensions] [Customer - Order Summary]
        // [SCENARIO 313866] Report "Customer - Order Summary" doesn't ignore Sales Lines with Dimension in "Shortcut Dimension 1 Code"
        Initialize;

        // [GIVEN] Sales Order with Sales Line with "Dimesnion Value" in "Shortcut Dimension 1 Code"
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocumentWithLine(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.");
        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 1 Code");
        SalesLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        SalesLine.Modify(true);

        // [WHEN] Customer - Order Summary is run.
        LibraryVariableStorage.Enqueue(WorkDate);
        LibraryVariableStorage.Enqueue(false);
        Commit();
        REPORT.Run(REPORT::"Customer - Order Summary", true, false, Customer);

        // [THEN] Sales Order Amount equal to Sales Line's "Quantity" * "Unit Price".
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('SalesOrderAmount', SalesLine.Quantity * SalesLine."Unit Price");
    end;

    [Test]
    [HandlerFunctions('StandardSalesOrderConfExcelRequestPageHandler,SimpleMessageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesOrderConfAssemblyComponentsRDLC()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemComponentCode: array[3] of Code[20];
    begin
        // [FEATURE] [Order] [Confirmation] [Excel] [Layout]
        // [SCENARIO 323241] Report "Standard Sales - Order Conf." show assembly components when printed with RDLC layout
        Initialize;
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);

        // [GIVEN] Report "Standard Sales - Order Conf." RDLC layout selected
        SetRDLCReportLayout(REPORT::"Standard Sales - Order Conf.");

        // [GIVEN] Parent "Item" with setup for assembly to order policy with 3 components
        CreateItemWithAssemblyComponents(Item, ItemComponentCode);

        // [GIVEN] Sales Order with "Item" in the line
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [WHEN] Run "Standard Sales - Order Conf." report with "Show Assembly Components" checkbox enabled
        LibraryVariableStorage.Enqueue(true);
        RunStandardSalesOrderConfirmationReport(SalesHeader."No.");

        // [THEN] Assembly Components are printed
        VerifyExcelWithItemAssemblyComponents(ItemComponentCode);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceExcelRequestPageHandler,SimpleMessageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesInvoiceAssemblyComponentsRDLC()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemComponentCode: array[3] of Code[20];
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Posted] [Invoice] [Excel] [Layout]
        // [SCENARIO 323241] Report "Standard Sales - Invoice" show assembly components when printed with RDLC layout
        Initialize;
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);

        // [GIVEN] Report "Standard Sales - Invoice" RDLC layout selected
        SetRDLCReportLayout(REPORT::"Standard Sales - Invoice");

        // [GIVEN] Parent "Item" with setup for assembly to order policy with 3 components
        CreateItemWithAssemblyComponents(Item, ItemComponentCode);

        // [GIVEN] Sales Order with "Item" in the line
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run "Standard Sales - Order Conf." report with "Show Assembly Components" checkbox enabled
        LibraryVariableStorage.Enqueue(true);
        RunStandardSalesInvoiceReport(PostedDocumentNo);

        // [THEN] Assembly Components are printed
        VerifyExcelWithItemAssemblyComponents(ItemComponentCode);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('StdSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesInvoiceCustomerCrossReferenceNo()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DummySalesInvoiceLine: Record "Sales Invoice Line";
        ItemCrossReferenceNo: Code[20];
    begin
        // [FEATURE] [Posted] [Invoice] [Item Cross Reference]
        // [SCENARIO 345453] "Cross Reference No." is included in "Standard Sales - Invoice" Report
        Initialize;

        // [GIVEN] Item Cross Reference "ITC" for Customer "C" and Item "I"
        ItemCrossReferenceNo := CreateCustomerItemCrossReferenceNo(Customer, Item);

        // [GIVEN] Posted Sales Invoice for Customer "C" and Item "I"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, true));

        // [WHEN] Run "Standard Sales - Invoice" Report
        RunStandardSalesInvoiceReport(SalesInvoiceHeader."No.");
        LibraryReportDataset.LoadDataSetFile;

        // [THEN] Value "ITC" is displayed under tag <CrossReferenceNo_Line> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('CrossReferenceNo_Line', ItemCrossReferenceNo);

        // [THEN] Value "Cross-Reference No." is displayed under tag <CrossReferenceNo_Line_Lbl> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists(
          'CrossReferenceNo_Line_Lbl', DummySalesInvoiceLine.FieldCaption("Cross-Reference No."));
    end;

    [Test]
    [HandlerFunctions('StdSalesCrMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesCreditMemoCustomerCrossReferenceNo()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DummySalesCrMemoLine: Record "Sales Cr.Memo Line";
        ItemCrossReferenceNo: Code[20];
    begin
        // [FEATURE] [Posted] [Credit Memo] [Item Cross Reference]
        // [SCENARIO 345453] "Cross Reference No." is included in "Standard Sales - Credit Memo" Report
        Initialize;

        // [GIVEN] Item Cross Reference "ITC" for Customer "C" and Item "I"
        ItemCrossReferenceNo := CreateCustomerItemCrossReferenceNo(Customer, Item);

        // [GIVEN] Posted Sales Credit Memo for Customer "C" and Item "I"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, true));

        // [WHEN] Run "Standard Sales - Credit Memo" Report
        Commit;
        SalesCrMemoHeader.SetRecFilter;
        REPORT.Run(REPORT::"Standard Sales - Credit Memo", true, false, SalesCrMemoHeader);
        LibraryReportDataset.LoadDataSetFile;

        // [THEN] Value "ITC" is displayed under tag <CrossReferenceNo_Line> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('CrossReferenceNo_Line', ItemCrossReferenceNo);

        // [THEN] Value "Cross-Reference No." is displayed under tag <CrossReferenceNo_Line_Lbl> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists(
          'CrossReferenceNo_Line_Lbl', DummySalesCrMemoLine.FieldCaption("Cross-Reference No."));
    end;

    [Test]
    [HandlerFunctions('StandardSalesQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StdSalesQuoteCustomerCrossReferenceNo()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemCrossReferenceNo: Code[20];
    begin
        // [FEATURE] [Quote] [Item Cross Reference]
        // [SCENARIO 345453] "Cross Reference No." is included in "Standard Sales - Quote" Report
        Initialize;

        // [GIVEN] Item Cross Reference "ITC" for Customer "C" and Item "I"
        ItemCrossReferenceNo := CreateCustomerItemCrossReferenceNo(Customer, Item);

        // [GIVEN] Sales Quote for Customer "C" and Item "I"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // [WHEN] Run report "Standard Sales - Quote".
        Commit;
        SalesHeader.SetRecFilter;
        REPORT.Run(REPORT::"Standard Sales - Quote", true, false, SalesHeader);
        LibraryReportDataset.LoadDataSetFile;

        // [THEN] Value "ITC" is displayed under tag <CrossReferenceNo_Line> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('CrossReferenceNo_Line', ItemCrossReferenceNo);

        // [THEN] Value "Cross-Reference No." is displayed under tag <CrossReferenceNo_Line_Lbl> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('CrossReferenceNo_Line_Lbl', SalesLine.FieldCaption("Cross-Reference No."));
    end;

    [Test]
    [HandlerFunctions('DraftSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DraftSalesInvoiceCustomerCrossReferenceNo()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemCrossReferenceNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Item Cross Reference]
        // [SCENARIO 345453] "Cross Reference No." is included in "Standard Sales - Draft Invoice" Report
        Initialize;

        // [GIVEN] Item Cross Reference "ITC" for Customer "C" and Item "I"
        ItemCrossReferenceNo := CreateCustomerItemCrossReferenceNo(Customer, Item);

        // [GIVEN] Sales Invoice for Customer "C" and Item "I"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // [WHEN] Run report "Standard Sales - Draft Invoice".
        Commit;
        SalesHeader.SetRecFilter;
        REPORT.Run(REPORT::"Standard Sales - Draft Invoice", true, false, SalesHeader);
        LibraryReportDataset.LoadDataSetFile;

        // [THEN] Value "ITC" is displayed under tag <CrossReferenceNo_Line> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('CrossReferenceNo_Line', ItemCrossReferenceNo);

        // [THEN] Value "Cross-Reference No." is displayed under tag <CrossReferenceNo_Line_Lbl> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('CrossReferenceNo_Line_Lbl', SalesLine.FieldCaption("Cross-Reference No."));
    end;

    [Test]
    [HandlerFunctions('CustomerDetailedAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetailedAgingHasProperCaption()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer] [Customer Detailed Aging]
        // [SCENARIO 349053] Report "Customer Detailed Aging" shows proper caption text for Customer when running with a filter.
        Initialize();

        // [GIVEN] Customer was created
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] An invoice was posted for the Customer
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, Customer."No.", '', LibraryRandom.RandDec(100, 2), WorkDate);

        // [WHEN] The Customer Detailed Aging report is ran with a filter
        RunCustomerDetailedAging(GenJournalLine);
        // UI handled by CustomerDetailedAgingRequestPageHandler

        // [THEN] Resulting dataset has Customer table caption in it
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Customer_TABLECAPTION_CustFilter',
          StrSubstNo('%1: %2: %3', Customer.TableCaption, Customer.FieldCaption("No."), Customer."No."));
    end;

    [Test]
    [HandlerFunctions('StdSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceVATAmountSpecification()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 360359] Report "Standard Sales - Invoice" contains "VAT Amount Specification", when
        // [SCENARIO 360359] "VAT %" = 0, "VAT Clause Code" = '', and Amount = "Amount Including VAT"
        Initialize();

        // [GIVEN] Using RDLC layout for "Standard Sales - Invoice" report

        SetRDLCReportLayout(REPORT::"Standard Sales - Invoice");

        // [GIVEN] Posted Sales Invoice with Sales Line, for which
        // [GIVEN] "VAT %" = 0, "VAT Clause Code" = '', and Amount = "Amount Including VAT"
        LibrarySales.CreateSalesInvoice(SalesHeader);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("VAT %", 0);
        SalesLine.Validate("VAT Clause Code", '');
        SalesLine.Modify(true);
        SalesLine.TestField(Amount, SalesLine."Amount Including VAT");

        // [WHEN] Report "Standard Sales - Invoice" is run for Posted Sales Invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, false));
        SalesInvoiceHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

        // [THEN] Report contains "VAT Amount Specification" section
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementTagExists('VATAmountSpecification_Lbl');
    end;

    [Test]
    [HandlerFunctions('StdSalesCrMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesCreditMemoVATAmountSpecification()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 360359] Report "Standard Sales - Credit Memo" contains "VAT Amount Specification", when
        // [SCENARIO 360359] "VAT %" = 0, "VAT Clause Code" = '', and Amount = "Amount Including VAT"
        Initialize();

        // [GIVEN] Using RDLC layout for "Standard Sales - Credit Memo" report
        SetRDLCReportLayout(REPORT::"Standard Sales - Credit Memo");

        // [GIVEN] Posted Sales Credit Memo with Sales Line, for which
        // [GIVEN] "VAT %" = 0, "VAT Clause Code" = '', and Amount = "Amount Including VAT"
        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("VAT %", 0);
        SalesLine.Validate("VAT Clause Code", '');
        SalesLine.Modify(true);
        SalesLine.TestField(Amount, SalesLine."Amount Including VAT");

        // [WHEN] Report "Standard Sales - Credit Memo" is run for Posted Sales Credit Memo
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesCrMemoHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Credit Memo", true, false, SalesCrMemoHeader);

        // [THEN] Report contains "VAT Amount Specification" section
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementTagExists('VATAmountSpecification_Lbl');
    end;

    [Test]
    [HandlerFunctions('CustomerDetailedAgingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDetailedAgingDueMonthsCalculation()
    var
        GenJournalLine: array[4] of Record "Gen. Journal Line";
        Customer: Record Customer;
        DueDate: array[4] of Date;
        EndingDate: Date;
        i: Integer;
        Year: Integer;
        Month: Integer;
        Day: Integer;
    begin
        // [FEATURE] [Customer] [Customer Detailed Aging]
        // [SCENARIO 360075] Report "Customer Detailed Aging" shows consistent Due Months when dates are set in months with different amount of days
        Initialize();

        // [GIVEN] Customer was created
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Ending Date = 20/7/2022
        Year := Date2DMY(WorkDate, 3) + LibraryRandom.RandInt(5);
        Month := LibraryRandom.RandIntInRange(5, 10);
        Day := LibraryRandom.RandIntInRange(10, 25);
        EndingDate := DMY2Date(Day, Month, Year);

        // [GIVEN] Due Date 1 = 01/03/2022
        DueDate[1] := DMY2Date(1, Month - 4, Year);

        // [GIVEN] Due Date 2 = 25/03/2022
        DueDate[2] := DMY2Date(Day + LibraryRandom.RandIntInRange(2, 9), Month - 4, Year);

        // [GIVEN] Due Date 3 = 15/04/2022
        DueDate[3] := DMY2Date(Day - LibraryRandom.RandIntInRange(2, 8), Month - 3, Year);

        // [GIVEN] Due Date 4 = 30/04/2021
        DueDate[4] := CalcDate('<CM>', DMY2Date(1, Month - 3, Year - 1));

        // [GIVEN] 4 invoices were posted for the Customer with Due Dates 1 to 4
        for i := 1 to ArrayLen(GenJournalLine) do
            CreatePostGeneralJournalLineWithDueDate(
              GenJournalLine[i], GenJournalLine[i]."Document Type"::Invoice,
              Customer."No.", '', LibraryRandom.RandDec(100, 2), WorkDate, DueDate[i]);

        // [WHEN] The Customer Detailed Aging report is ran for customer with Ending Date
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(Customer."No.");
        REPORT.Run(REPORT::"Customer Detailed Aging");
        // UI handled by CustomerDetailedAgingRequestPageHandler

        LibraryReportDataset.LoadDataSetFile;
        // [THEN] DueMonths for Due Date 1 is 4
        VerifyDueMonthsForDueDate(DueDate[1], 4);

        // [THEN] DueMonths for Due Date 2 is 3
        VerifyDueMonthsForDueDate(DueDate[2], 3);

        // [THEN] DueMonths for Due Date 3 is 3
        VerifyDueMonthsForDueDate(DueDate[3], 3);

        // [THEN] DueMonths for Due Date 4 is 14
        VerifyDueMonthsForDueDate(DueDate[4], 14);
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesStatisticsReportForNonInventoryItem()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Non-Inventory Item]
        // [SCENARIO 359883] Cost of a non-inventory item in Sales Statistics report.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Non-inventory item with "Unit Cost" = 10 and "Unit Price" = 30.
        LibraryInventory.CreateNonInventoryTypeItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Unit Price", LibraryRandom.RandDecInRange(200, 400, 2));
        Item.Modify(true);

        // [GIVEN] Sales order for 1 pc of the non-inventory item.
        // [GIVEN] Ship and invoice the sales order.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run "Sales Statistics" report.
        Commit;
        Customer.SetRecFilter();
        REPORT.Run(REPORT::"Sales Statistics", true, false, Customer);

        // [THEN] The report shows "Profit" = 20, and "Adjusted Cost" = 10.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CustProfitLCY2', Item."Unit Price" - Item."Unit Cost");
        LibraryReportDataset.AssertElementWithValueExists('CustSalProfAdjmtCostLCY2', Item."Unit Cost");
    end;

    [Test]
    [HandlerFunctions('CustomerItemSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerItemSalesEmptyDataset()
    var
        Customer: Record Customer;
    begin
        // [SCENARIO 364816] Report "Customer/Item Sales" shows message 'There is nothing to print for the selected filters.' when resulting dataset is empty.
        Initialize();

        // [WHEN] Report "Customer/Item Sales" is run for non-existing Customer.
        LibraryVariableStorage.Enqueue(LibraryRandom.RandText(MaxStrLen(Customer."No.")));
        Commit();
        asserterror REPORT.Run(REPORT::"Customer/Item Sales");

        // [THEN] Report dataset is empty and error 'There is nothing to print for the selected filters.' is shown.
        Assert.ExpectedError(EmptyReportDatasetTxt);
        Assert.ExpectedErrorCode('Dialog');
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(0, LibraryReportDataset.RowCount(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceJobNoAndJobTaskNo()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // [SCENARIO 370287] "Standard Sales - Invoice" report dataset has "Job No" and "Job Task No" from Sales Invoice line.
        Initialize();

        // [GIVEN] Sales Invoice with Sales Invoice Line with Job No and Job Task No.
        MockSalesInvoiceHeaderWithExternalDocumentNo(SalesInvoiceHeader);
        MockSalesInvoiceLineWithJobNoAndJobTaskNo(SalesInvoiceLine, SalesInvoiceHeader."No.");

        // [WHEN] Report "Standard Sales - Invoice" is run for Sales Invoice.
        RunStandardSalesInvoiceReport(SalesInvoiceHeader."No.");

        // [THEN] Resulting dataset has Job No and Job Task No.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('JobNo', SalesInvoiceLine."Job No.");
        LibraryReportDataset.AssertElementWithValueExists('JobTaskNo', SalesInvoiceLine."Job Task No.");
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales Report");
        LibrarySetupStorage.Restore;
        LibraryVariableStorage.Clear;

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales Report");

        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibrarySales.SetInvoiceRounding(false);

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales Report");
    end;

    local procedure UpdateGeneralLedgerSetup(VATSpecificationInLCY: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        with GeneralLedgerSetup do begin
            Get;
            "Print VAT specification in LCY" := VATSpecificationInLCY;
            Modify(true);
        end;
    end;

    local procedure ModifyLanguageWindowsLanguageID(LanguageCode: Code[10]; WindowsLanguageID: Integer)
    var
        Language: Record Language;
    begin
        Language.Get(LanguageCode);
        Language.Validate("Windows Language ID", WindowsLanguageID);
        Language.Modify(true);
    end;

    local procedure ClearGenJournalLine(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure CreateAndPostInvoice(AccountNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        ClearGenJournalLine(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, AccountNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateApplyAndPostPayment(AccountNo: Code[20]; AppliesToInvoiceNo: Code[20]; CurrencyCode: Code[10]; PmtAmount: Decimal): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        ClearGenJournalLine(GenJournalBatch);
        with GenJournalLine do begin
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, "Document Type"::Payment,
              "Account Type"::Customer, AccountNo, PmtAmount);
            Validate("Applies-to Doc. Type", "Applies-to Doc. Type"::Invoice);
            Validate("Applies-to Doc. No.", AppliesToInvoiceNo);
            Validate("Currency Code", CurrencyCode);
            Modify(true);
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"): Code[20]
    begin
        // Create Sales Order with Random Quantity.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(10));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesOrderWithQtyToAssemble(CustomerNo: Code[20]; ShipmentDate: Date; ItemNo: Code[20]; Invoice: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Order Date", ShipmentDate);
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        SalesLine.Validate("Qty. to Assemble to Order", SalesLine.Quantity);
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, Invoice));
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Option; ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo,
          LibraryRandom.RandDecInRange(50, 100, 2)); // Use random Quantity.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAssemblyComponent(ParentItemNo: Code[20]): Code[20]
    var
        AssemblyItem: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        LibraryAssembly.CreateItem(AssemblyItem, AssemblyItem."Costing Method"::FIFO, AssemblyItem."Replenishment System"::Purchase, '', '');
        LibraryManufacturing.CreateBOMComponent(
          BOMComponent, ParentItemNo, BOMComponent.Type::Item,
          AssemblyItem."No.", LibraryRandom.RandDec(2, 4), AssemblyItem."Base Unit of Measure");
        BOMComponent.Validate(Description, AssemblyItem."No.");
        BOMComponent.Modify(true);
        exit(AssemblyItem."No.");
    end;

    local procedure CreateAndSetupSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Option)
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        CurrencyCode: Code[10];
        ExchangeRate: Decimal;
        LineQuantity: Decimal;
        LineUnitPrice: Decimal;
        VATPercent: Integer;
    begin
        // Certain values to get rounding error
        LineQuantity := 1;
        LineUnitPrice := 2575872;
        ExchangeRate := 1.284;
        VATPercent := 10;

        // Init setups
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, ExchangeRate, ExchangeRate);

        // Cteare and post document
        CreateVATPostingGroup(VATPostingSetup, VATPercent);
        LibrarySales.CreateSalesHeader(
          SalesHeader, DocumentType, LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        with SalesHeader do begin
            Validate("Posting Date", WorkDate);
            Validate("Currency Code", CurrencyCode);
            Modify(true);
        end;

        with SalesLine do begin
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, Type::"G/L Account",
              LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale), LineQuantity);
            Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            Validate("Unit Price", LineUnitPrice);
            Modify(true);
        end;
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        // Create a new Customer with Address and Application Method : Apply to Oldest.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Address, 'Address: ' + Customer."No.");
        Customer.Validate("Phone No.", Format(LibraryRandom.RandIntInRange(100000000, 999999999)));
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithVATPostingSetup(var VATProdPostingGroupCode: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATPostingGroup(VATPostingSetup, LibraryRandom.RandIntInRange(30, 40));
        VATProdPostingGroupCode := VATPostingSetup."VAT Prod. Posting Group";
        exit(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
    end;

    local procedure CreateCustomerWithLanguageCode(LanguageCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Language Code", LanguageCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithDefaultGlobalDimValues(var Customer: Record Customer; var DimValueCode: array[2] of Code[20])
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        i: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        for i := 1 to 2 do begin
            LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(i));
            LibraryDimension.CreateDefaultDimensionCustomer(
              DefaultDimension, Customer."No.", DimensionValue."Dimension Code", DimensionValue.Code);
            DimValueCode[i] := DimensionValue.Code;
        end;
    end;

    local procedure CreateCustomerItemCrossReferenceNo(var Customer: Record Customer; var Item: Record Item): Code[20]
    var
        ItemCrossReference: Record "Item Cross Reference";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemCrossReference(
          ItemCrossReference, Item."No.", ItemCrossReference."Cross-Reference Type"::Customer, Customer."No.");
        exit(ItemCrossReference."Cross-Reference No.");
    end;

    local procedure CreateItemTranslation(ItemNo: Code[20]; LanguageCode: Code[10]): Text[50]
    var
        ItemTranslation: Record "Item Translation";
    begin
        with ItemTranslation do begin
            Init;
            Validate("Item No.", ItemNo);
            Validate("Language Code", LanguageCode);
            Validate(Description, ItemNo + LanguageCode);
            Insert(true);
            exit(Description);
        end;
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Option; CustomerNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryERM: Codeunit "Library - ERM";
    begin
        ClearGenJournalLine(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePostGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Option; CustomerNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; PostingDate: Date)
    var
        LibraryERM: Codeunit "Library - ERM";
    begin
        CreateGeneralJournalLine(GenJournalLine, DocumentType, CustomerNo, CurrencyCode, Amount, PostingDate);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure MockSalesOrderWithExternalDocumentNo(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader."No." := LibraryUtility.GenerateGUID;
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."External Document No." := LibraryUtility.GenerateGUID;
        SalesHeader.Insert();
    end;

    local procedure MockSalesInvoiceHeaderWithExternalDocumentNo(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID;
        SalesInvoiceHeader."External Document No." := LibraryUtility.GenerateGUID;
        SalesInvoiceHeader.Insert();
    end;

    local procedure MockSalesInvoiceLineWithJobNoAndJobTaskNo(var SalesInvoiceLine: Record "Sales Invoice Line"; SalesInvoiceHeaderNo: Code[20])
    begin
        SalesInvoiceLine."Document No." := SalesInvoiceHeaderNo;
        SalesInvoiceLine."Line No." := 10000;
        SalesInvoiceLine.Description := SalesInvoiceLine."Document No.";
        SalesInvoiceLine."Job No." := LibraryUtility.GenerateGUID();
        SalesInvoiceLine."Job Task No." := LibraryUtility.GenerateGUID();
        SalesInvoiceLine.Insert();
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10]; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CurrencyCode: Code[10]; CustomerNo: Code[20])
    begin
        CreateSalesHeader(SalesHeader, CurrencyCode, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithPaymentMethod(var SalesHeader: Record "Sales Header"; DocType: Integer; PaymentMethodCode: Code[10]; CustNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocumentWithLine(SalesHeader, SalesLine, DocType, CustNo);
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesDocumentWithLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Option; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesQuoteWithLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20])
    begin
        CreateSalesDocumentWithLine(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote, CustomerNo);
    end;

    local procedure CreateSalesInvoiceWithLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20])
    begin
        CreateSalesDocumentWithLine(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, CustomerNo);
    end;

    local procedure CreateSalesInvoiceWithThreeLinesWithVATBusPostingSetup(var SalesHeader: Record "Sales Header"; VATPostingSetup: array[3] of Record "VAT Posting Setup")
    var
        Customer: Record Customer;
        i: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup[3]."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        for i := 1 to ArrayLen(VATPostingSetup) do
            CreateSalesLineWithItemWithVATPostingSetup(SalesHeader, VATPostingSetup[i]);
    end;

    local procedure CreateSalesCreditMemoWithLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20])
    begin
        CreateSalesDocumentWithLine(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
    end;

    local procedure CreateSalesOrderWithTwoLines(var CustomerNo: Code[20]; var ExpectedAmount: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        ItemNo: Code[20];
    begin
        // Line Amount Incl. VAT = Line Amount Excl. VAT * (1 + VAT%).
        // Using hardcode of VAT% to leave out the third decimal places of Line Amount Incl. VAT
        CreateVATPostingGroup(VATPostingSetup, 19.6);
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        ItemNo := CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        // Outstanding Order = Line Amount Incl. VAT(##0.00) / (1 + VAT%).
        // Using hardcode of Unit Price to leave out the third decimal places of Line Amount Incl. VAT when calculate Outstanding Order with VAT.
        CreateSalesLineWithVAT(SalesHeader, SalesLine1, ItemNo, 129);
        CreateSalesLineWithVAT(SalesHeader, SalesLine2, ItemNo, 79);
        ExpectedAmount := Round(SalesLine1.Amount * SalesLine1."Outstanding Quantity" / SalesLine1.Quantity) +
          Round(SalesLine2.Amount * SalesLine2."Outstanding Quantity" / SalesLine2.Quantity);
    end;

    local procedure CreateSalesInvoiceWithExternalDocNo(var SalesHeader: Record "Sales Header")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer);
        SalesHeader.Validate("External Document No.", CopyStr(LibraryUtility.GenerateRandomXMLText(35), 1, 35));
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLineWithVAT(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; UnitPrice: Decimal)
    begin
        // Using hardcode to make sure the third decimal places of Line Amount Incl. VAT can be left out
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 1);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithItemWithVATProdPostingGroup(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATProdPostingGroupCode: Code[20])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItemWithVATProdPostingGroup(VATProdPostingGroupCode),
          LibraryRandom.RandIntInRange(10, 100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 1000));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithItemWithVATPostingSetup(SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateEmptySalesLineWithDescription(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LibraryUtility.GetNewRecNo(SalesLine, SalesLine.FieldNo("Line No."));
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine.Insert();
        LibraryUtility.FillFieldMaxText(SalesLine, SalesLine.FieldNo(Description));
    end;

    local procedure CreateCustomerWithCurrencyCode(var Customer: Record Customer)
    var
        Currency: Record Currency;
    begin
        LibraryERM.FindCurrency(Currency);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", Currency.Code);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithPhoneAndFaxNo(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Phone No.", LibraryUtility.GenerateRandomNumericText(10));
        Customer.Validate("Fax No.", LibraryUtility.GenerateRandomNumericText(10));
        Customer.Modify(true);
    end;

    local procedure CreateVATPostingGroup(var VATPostingSetup: Record "VAT Posting Setup"; VATPercent: Decimal)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        CreateVATPostingSetupWithAccountsForBusPostingGroup(VATPostingSetup, VATBusinessPostingGroup.Code, VATPercent);
    end;

    local procedure CreateVATPostingSetupWithAccountsForBusPostingGroup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroupCode: Code[20]; VATPercent: Decimal)
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroupCode, VATProdPostingGroup.Code);
        with VATPostingSetup do begin
            Init;
            Validate("VAT Identifier", 'VAT' + Format(VATPercent));
            Validate("VAT %", VATPercent);
            Validate("Sales VAT Account", GLAccount."No.");
            Validate("Purchase VAT Account", GLAccount."No.");
            Modify(true);
        end;
    end;

    local procedure CreateVATProdPostingGroupWithPercent(VATBusPostingGroupCode: Code[20]; VATPercent: Decimal): Code[20]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", VATPercent);
        VATPostingSetup.Modify(true);
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateThreeVATPostingSetupsWithTwoVATClauses(var VATPostingSetup: array[3] of Record "VAT Posting Setup"; var VATClause: array[2] of Record "VAT Clause")
    var
        VATProductPostingGroup: array[2] of Record "VAT Product Posting Group";
        i: Integer;
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup[3], VATPostingSetup[3]."VAT Calculation Type"::"Normal VAT", 0);
        for i := 1 to ArrayLen(VATClause) do begin
            LibraryERM.CreateVATClause(VATClause[i]);
            LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup[i]);
            VATPostingSetup[i].Init();
            VATPostingSetup[i] := VATPostingSetup[3];
            VATPostingSetup[i].Validate("VAT Identifier", LibraryUtility.GenerateGUID);
            VATPostingSetup[i].Validate("VAT Prod. Posting Group", VATProductPostingGroup[i].Code);
            VATPostingSetup[i].Validate("VAT %", LibraryRandom.RandInt(10));
            VATPostingSetup[i].Validate("VAT Clause Code", VATClause[i].Code);
            VATPostingSetup[i].Insert(true);
        end;
    end;

    local procedure CreateItemWithVATProdPostingGroup(VATProdPostingGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithAssemblyComponents(var Item: Record Item; var ItemComponentCode: array[3] of Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        Index: Integer;
    begin
        LibraryAssembly.CreateItem(Item, Item."Costing Method"::FIFO, Item."Replenishment System"::Assembly, '', '');
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Validate(Description, LibraryUtility.GenerateGUID);
        Item.Modify(true);
        for Index := 1 to ArrayLen(ItemComponentCode) do begin
            ItemComponentCode[Index] := CreateAssemblyComponent(Item."No.");
            CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemComponentCode[Index]);
        end;
    end;

    local procedure CreateGlobalDimValues(var GlobalDim1Value: Code[20]; var GlobalDim2Value: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        GlobalDim1Value := DimensionValue.Code;
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 2 Code");
        GlobalDim2Value := DimensionValue.Code;
    end;

    local procedure CreatePostSalesCrMemoWithYourRef(var PostedCrMemoNo: Code[20]; var YourReference: Text[35])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandIntInRange(1, 10));
        LibraryUtility.FillFieldMaxText(SalesHeader, SalesHeader.FieldNo("Your Reference"));
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        PostedCrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        YourReference := SalesHeader."Your Reference";
    end;

    local procedure CreatePostGeneralJournalLineWithDueDate(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Option; CustomerNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; PostingDate: Date; DueDate: Date)
    var
        LibraryERM: Codeunit "Library - ERM";
    begin
        CreateGeneralJournalLine(GenJournalLine, DocumentType, CustomerNo, CurrencyCode, Amount, PostingDate);
        GenJournalLine.Validate("Due Date", DueDate);
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCurrencyWithFixedExchRates(RelExchRateAmount: Decimal): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 1);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelExchRateAmount);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", RelExchRateAmount);
        CurrencyExchangeRate.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateShipmentMethod(var ShipmentMethod: Record "Shipment Method")
    begin
        with ShipmentMethod do begin
            Init;
            Code := LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Shipment Method");
            Description := LibraryUtility.GenerateGUID;
            Insert(true);
        end;
    end;

    local procedure ReleaseSalesOrder(var SalesHeader: Record "Sales Header"; DocumentType: Option; CustomerNo: Code[20])
    begin
        SalesHeader.SetRange("Document Type", DocumentType);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.FindFirst;
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure ConvertCurrency(Amount: Decimal; CurrencyCode: Code[10]): Decimal
    begin
        exit(Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate)));
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Option; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst;
    end;

    local procedure FindGLEntry(DocumentNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindLast;
        exit(GLEntry."Transaction No.");
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20]; PostingDate: Date; VATProdPostingGroup: Code[20])
    begin
        VATEntry.SetRange("Posting Date", PostingDate);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
        VATEntry.FindFirst;
    end;

    local procedure GetCustomerBalanceLCY() TotalBalance: Decimal
    var
        Customer: Record Customer;
    begin
        TotalBalance := 0;
        with Customer do begin
            SetFilter("Balance (LCY)", '>0');
            if FindSet then
                repeat
                    CalcFields("Balance (LCY)");
                    TotalBalance += "Balance (LCY)";
                until Next = 0;
        end;
    end;

    local procedure GetCustomerSalesLCY() TotalSalesLCY: Decimal
    var
        Customer: Record Customer;
    begin
        TotalSalesLCY := 0;
        with Customer do begin
            SetFilter("Sales (LCY)", '>0');
            if FindSet then
                repeat
                    CalcFields("Sales (LCY)");
                    TotalSalesLCY += "Sales (LCY)";
                until Next = 0;
        end;
    end;

    local procedure GetPostingDate(): Date
    var
        DateComprRegister: Record "Date Compr. Register";
    begin
        DateComprRegister.SetCurrentKey("Table ID", "Ending Date");
        DateComprRegister.SetRange("Table ID", DATABASE::"G/L Entry");
        if DateComprRegister.FindLast then
            exit(CalcDate('<1D>', DateComprRegister."Ending Date")); // Next Day
        exit(WorkDate);
    end;

    local procedure GetRandomLanguageCode(): Code[10]
    var
        Language: Record Language;
        RandomNum: Integer;
    begin
        Language.Init();
        RandomNum := LibraryRandom.RandIntInRange(1, Language.Count);
        Language.Next(RandomNum);
        exit(Language.Code);
    end;

    local procedure LanguageCodeForAssemblyItemsSetup(var Customer: Record Customer; var ParentItem: Record Item): Text[50]
    var
        ItemJournalLine: Record "Item Journal Line";
        AssemblyItemNo: Code[20];
    begin
        // Create Customer with Language Code.
        Customer.Get(CreateCustomerWithLanguageCode(GetRandomLanguageCode));

        // Create Item with Assembly Component. Update Inventory for Assembly Item.
        LibraryAssembly.CreateItem(ParentItem, ParentItem."Costing Method"::FIFO, ParentItem."Replenishment System"::Assembly, '', '');
        AssemblyItemNo := CreateAssemblyComponent(ParentItem."No.");
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", AssemblyItemNo);

        // Create Item Translation for Assembly Item.
        exit(CreateItemTranslation(AssemblyItemNo, Customer."Language Code")); // Return Translation Description for Assembly Item
    end;

    local procedure ModifyUnitPriceInSalesLine(var SalesLine: Record "Sales Line"; UnitPrice: Decimal)
    begin
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreatePostDebitCreditJournalLines(var DebitAmount: Decimal; var CreditAmount: Decimal; CustomerNo: Code[20]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        DebitAmount := LibraryRandom.RandDec(1000, 2);
        CreditAmount := -LibraryRandom.RandDec(1000, 2);
        PostJournalLines(GenJournalLine, CustomerNo, DebitAmount, CreditAmount);
        exit(GenJournalLine."Account No.");
    end;

    local procedure CreateDebitCreditJournalLines(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        ClearGenJournalLine(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustomerNo, DebitAmount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustomerNo, CreditAmount);
    end;

    local procedure CreateDebitCreditJournalLinesWithDimensions(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal; Dimension1Value: Code[20]; Dimension2Value: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        ClearGenJournalLine(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustomerNo, DebitAmount);
        UpdateGenJnlLineDim(GenJournalLine, Dimension1Value, Dimension2Value);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CustomerNo, CreditAmount);
        UpdateGenJnlLineDim(GenJournalLine, Dimension1Value, Dimension2Value);
    end;

    local procedure UpdateGenJnlLineDim(var GenJournalLine: Record "Gen. Journal Line"; Dimension1Value: Code[20]; Dimension2Value: Code[20])
    begin
        GenJournalLine.Validate("Shortcut Dimension 1 Code", Dimension1Value);
        GenJournalLine.Validate("Shortcut Dimension 2 Code", Dimension2Value);
        GenJournalLine.Modify();
    end;

    local procedure UpdateGlobalDims()
    var
        Dimension: array[2] of Record Dimension;
    begin
        if (LibraryERM.GetGlobalDimensionCode(1) = '') or (LibraryERM.GetGlobalDimensionCode(2) = '') then begin
            LibraryDimension.CreateDimension(Dimension[1]);
            LibraryDimension.CreateDimension(Dimension[2]);
            LibraryDimension.RunChangeGlobalDimensions(Dimension[1].Code, Dimension[2].Code);
        end;
    end;

    local procedure PostJournalLines(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal)
    begin
        CreateDebitCreditJournalLines(GenJournalLine, CustomerNo, DebitAmount, CreditAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostSalesOrderForAssemblyItemsWithLanguageCode(PostInvoice: Boolean; Type: Option Invoice,Shipment)
    var
        Customer: Record Customer;
        ParentItem: Record Item;
        DocumentNo: Code[20];
        AssemblyItemTranslationDes: Text[50];
    begin
        // Setup: Create Customer with Language Code. Create Item with Assembly Component. Update Inventory and Create Item Translation for Assembly Item.
        Initialize;
        LibraryERMCountryData.CreateVATData;
        AssemblyItemTranslationDes := LanguageCodeForAssemblyItemsSetup(Customer, ParentItem);

        // Create and Post Sales Order with "Qty to Assemble to Order ".
        DocumentNo := CreateAndPostSalesOrderWithQtyToAssemble(
            Customer."No.", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate), ParentItem."No.", PostInvoice); // Post Ship only

        // Excercise: Run Report 206 (Sales - Invoice) / 208 (Sales - Shipment).
        // Verify: Description for Assembly Item is translated according to Language Code
        case Type of
            Type::Invoice:
                begin
                    RunSalesInvoiceReport(DocumentNo, false, false, true, 0); // Show Assembly Components = YES
                    VerifyXMLReport(PostedAsmLineDescCapTxt, '  ' + AssemblyItemTranslationDes); // Assembly Item has 2 (blank) indent before Translation Description in report
                end;
            Type::Shipment:
                begin
                    RunSalesShipmentReport(DocumentNo, false, false, false, true); // Show Assembly Components = YES
                    VerifyXMLReport(PostedAsmLineDescriptionCapTxt, '  ' + AssemblyItemTranslationDes); // Assembly Item has 2 (blank) indent before Translation Description in report
                end;
        end
    end;

    local procedure PostShipReceiveOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Option)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure ReverseTransaction(TransactionNo: Integer)
    var
        ReversalEntry: Record "Reversal Entry";
    begin
        LibraryVariableStorage.Enqueue(SuccessfullyReversedMessageMsg);
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(TransactionNo);
    end;

    local procedure ApplyPaymentToAllOpenInvoices(PmtNo: Code[20]; CustNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        ApplyingCustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(
          ApplyingCustLedgerEntry, GenJournalLine."Document Type"::Payment, PmtNo);
        ApplyingCustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(ApplyingCustLedgerEntry, ApplyingCustLedgerEntry."Remaining Amount");
        CustLedgerEntry.SetRange("Customer No.", CustNo);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange(Open, true);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
        LibraryERM.PostCustLedgerApplication(ApplyingCustLedgerEntry);
    end;

    local procedure RunAndVerifyCustomerRegister(DocumentNo: Code[20]; OriginalAmountLCY: Decimal)
    begin
        // Exercise: Generate the Customer Register report.
        REPORT.Run(REPORT::"Customer Register");

        // Verify: Check that the value of Original Amount in Customer Register is equal to the value of Amount in
        // corresponding General Journal Line.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('Cust__Ledger_Entry__Document_No__', DocumentNo);
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'Cust__Ledger_Entry__Document_No__', DocumentNo));
        LibraryReportDataset.AssertCurrentRowValueEquals('CustAmount', OriginalAmountLCY);
    end;

    local procedure RunAndVerifyCustomerTrialBal(GenJournalLine: Record "Gen. Journal Line"; AmountLCY: Decimal)
    begin
        // Exercise: Generate the Customer Detail Trial Balance Report.
        REPORT.Run(REPORT::"Customer - Detail Trial Bal.");

        // Verify: Check that the value of Amount in Customer Detail Trial Balance is equal to the value of Amount in
        // corresponding General Journal Line.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('DocNo_CustLedgEntry', GenJournalLine."Document No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'DocNo_CustLedgEntry', GenJournalLine."Document No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('CustLedgerEntryAmtLCY', AmountLCY);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceLCY', AmountLCY);
    end;

    local procedure RunCustomerDetailedAging(GenJournalLine: Record "Gen. Journal Line")
    begin
        // Enqueue values for CustomerDetailedAgingRequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalLine."Due Date");
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");

        // Run Customer Detailed Aging Report.
        REPORT.Run(REPORT::"Customer Detailed Aging");
    end;

    local procedure RunCustomerSummaryAgingReport(CustomerNo: Code[20]; ShowAmountInLCY: Boolean)
    var
        Customer: Record Customer;
        CustomerSummaryAging: Report "Customer - Summary Aging";
    begin
        Customer.SetRange("No.", CustomerNo);
        CustomerSummaryAging.SetTableView(Customer);
        CustomerSummaryAging.InitializeRequest(WorkDate, StrSubstNo('<%1M>', LibraryRandom.RandInt(5)), ShowAmountInLCY);
        Commit();
        CustomerSummaryAging.RunModal;
    end;

    local procedure RunAndVerifyCustSummaryAging(CustomerNo: Code[20]; ShowAmountLCY: Boolean; BalanceLCY: Decimal)
    begin
        // Exercise: Generate the Customer Summary Aging Report.
        RunCustomerSummaryAgingReport(CustomerNo, ShowAmountLCY);

        // Verify: Check that the value of Balance in Customer Summary Aging is equal to the value of Amount in
        // corresponding General Journal Line.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('Customer_No_', CustomerNo);
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'Customer_No_', CustomerNo));
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalCustBalanceLCY', BalanceLCY);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustBalanceDueLCY_3_', 0);
    end;

    local procedure RunCustomerOrderDetailReport(SellToCustomerNo: Code[20]; ShowAmountInLCY: Boolean)
    var
        Customer: Record Customer;
    begin
        LibraryVariableStorage.Enqueue(ShowAmountInLCY);
        LibraryVariableStorage.Enqueue(false);
        Customer.SetRange("No.", SellToCustomerNo);
        Commit();  // Due to limitation in page testability, commit is needed in this test case.
        REPORT.Run(REPORT::"Customer - Order Detail", true, false, Customer);
    end;

    local procedure RunCustomerOrderSummaryReport(var Customer: Record Customer)
    begin
        Customer.SetRange("No.", Customer."No.");
        Commit(); // Due to limitation in page testability, commit is needed in this test case.
        REPORT.Run(REPORT::"Customer - Order Summary", true, false, Customer);
    end;

    local procedure RunCustOrderSummaryReport(SellToCustomerNo: Code[20]; ShowAmountLCY: Boolean)
    var
        Customer: Record Customer;
    begin
        LibraryVariableStorage.Enqueue(WorkDate);
        LibraryVariableStorage.Enqueue(ShowAmountLCY);
        Customer.SetRange("No.", SellToCustomerNo);
        Commit();  // Due to limitation in page testability, commit is needed in this test case.
        REPORT.Run(REPORT::"Customer - Order Summary", true, false, Customer);
    end;

    local procedure RunSalesQuoteReport(No: Code[20]; InternalInfo: Boolean; Archived: Boolean; LogInteraction: Boolean; Print: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: Report "Sales - Quote";
    begin
        Clear(SalesQuote);
        SalesHeader.SetRange("No.", No);
        SalesQuote.SetTableView(SalesHeader);
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(InternalInfo);
        LibraryVariableStorage.Enqueue(Archived);
        LibraryVariableStorage.Enqueue(LogInteraction);
        LibraryVariableStorage.Enqueue(Print);

        SalesQuote.InitializeRequest(0, InternalInfo, Archived, LogInteraction, Print);
        Commit();
        SalesQuote.Run;
    end;

    local procedure RunSalesShipmentReport(No: Code[20]; ShowInternalInformation: Boolean; LogInteraction: Boolean; ShowCorrectionLines: Boolean; ShowAssemblyComponents: Boolean)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipment: Report "Sales - Shipment";
    begin
        Clear(SalesShipment);
        SalesShipmentHeader.SetRange("No.", No);
        SalesShipment.SetTableView(SalesShipmentHeader);
        SalesShipment.InitializeRequest(0, ShowInternalInformation, LogInteraction, ShowCorrectionLines, false, ShowAssemblyComponents); // NewShowLotSN is False
        Commit(); // Due to limitation in Report Commit is required for this Test case.
        SalesShipment.Run;
    end;

    local procedure RunSalesInvoiceReport(No: Code[20]; InternalInfo: Boolean; LogInteraction: Boolean; ShowAssemblyComponents: Boolean; NoOfCopies: Integer)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoice: Report "Sales - Invoice";
    begin
        Clear(SalesInvoice);
        SalesInvoiceHeader.SetRange("No.", No);
        SalesInvoice.SetTableView(SalesInvoiceHeader);
        SalesInvoice.InitializeRequest(NoOfCopies, InternalInfo, LogInteraction, false, false, false, ShowAssemblyComponents, false);
        Commit();
        SalesInvoice.Run;
    end;

    local procedure RunSalesCreditMemoReport(DocumentNo: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCreditMemoReport: Report "Sales - Credit Memo";
    begin
        SalesCrMemoHeader.SetRange("No.", DocumentNo);
        with SalesCreditMemoReport do begin
            SetTableView(SalesCrMemoHeader);
            InitializeRequest(0, false, false, false, false, false);
            Run;
        end;
    end;

    local procedure RunCustomerTrialBalanceReportForCY(CustomerNo: Code[20]; Dim1Filter: Code[20]; Dim2Filter: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.SetRange("No.", CustomerNo);
        Customer.SetRange("Date Filter", CalcDate('<-CY>', WorkDate), CalcDate('<CY>', WorkDate));
        Customer.SetFilter("Global Dimension 1 Filter", Dim1Filter);
        Customer.SetFilter("Global Dimension 2 Filter", Dim2Filter);
        REPORT.Run(REPORT::"Customer - Trial Balance", true, false, Customer);
    end;

    local procedure RunCustomerListReport(var Customer: Record Customer)
    begin
        Commit();
        Customer.SetRange("No.", Customer."No.");
        REPORT.Run(REPORT::"Customer - List", true, false, Customer);
    end;

    local procedure RunStandardSalesOrderConfirmationReport(SalesHeaderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        Commit();
        SalesHeader.SetRange("No.", SalesHeaderNo);
        REPORT.Run(REPORT::"Standard Sales - Order Conf.", true, false, SalesHeader);
    end;

    local procedure RunOrderConfirmationReport(SalesHeaderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        Commit();
        SalesHeader.SetRange("No.", SalesHeaderNo);
        REPORT.Run(REPORT::"Order Confirmation", true, false, SalesHeader);
    end;

    local procedure RunStandardSalesInvoiceReport(PostedSalesInvoiceNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        Commit();
        SalesInvoiceHeader.SetRange("No.", PostedSalesInvoiceNo);
        REPORT.Run(REPORT::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);
    end;

    local procedure RunDtldCustTrialBalanceReportWithDateFilter(CustNo: Code[20])
    var
        Customer: Record Customer;
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(CustNo);
        Commit();
        Customer.Get(CustNo);
        Customer.SetRecFilter;
        Customer.SetFilter("Date Filter", '%1..', WorkDate);
        REPORT.Run(REPORT::"Customer - Detail Trial Bal.", true, false, Customer);
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; ItemJournalTemplateType: Option)
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplateType, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SaveStatementReport(CustomerNo: Code[20]; PostingDate: Date; PrintOverdueEntries: Boolean; PrintReversedEntries: Boolean; PrintUnappliedEntries: Boolean; IncludeAgingBand: Boolean; PeriodLength: DateFormula)
    var
        Customer: Record Customer;
        Statement: Report Statement;
        DateChoice: Option "Due Date","Posting Date";
    begin
        Clear(Statement);
        Customer.SetRange("No.", CustomerNo);

        // Using 1 because Date Filter has to be set for two consecutive Years.
        Statement.SetTableView(Customer);
        Statement.InitializeRequest(
          PrintOverdueEntries, true, false, PrintReversedEntries, PrintUnappliedEntries, IncludeAgingBand,
          Format(PeriodLength), DateChoice::"Posting Date", false, DMY2Date(1, 1, Date2DMY(PostingDate, 3)),
          DMY2Date(31, 12, Date2DMY(CalcDate('<1Y>', PostingDate), 3)));
        Commit();
        Statement.Run;
    end;

    local procedure SetupInvoiceDiscount(var CustInvoiceDisc: Record "Cust. Invoice Disc.")
    begin
        // Required random value for Minimum Amount and Discount Pct fields, value is not important.
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CreateCustomer, '', LibraryRandom.RandInt(100));
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        CustInvoiceDisc.Modify(true);
    end;

    local procedure SetSalesHeaderInvoiceDiscountAmount(SalesHeader: Record "Sales Header"; InvoiceDiscountAmount: Decimal)
    var
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
    end;

    local procedure SetRDLCReportLayout(ReportID: Integer)
    var
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        ReportLayoutSelection.SetRange("Report ID", ReportID);
        ReportLayoutSelection.SetRange("Company Name", CompanyName);
        if ReportLayoutSelection.FindFirst then begin
            ReportLayoutSelection.Type := ReportLayoutSelection.Type::"RDLC (built-in)";
            ReportLayoutSelection."Custom Report Layout Code" := '';
            ReportLayoutSelection.Modify();
        end else begin
            ReportLayoutSelection."Report ID" := ReportID;
            ReportLayoutSelection."Company Name" := CompanyName;
            ReportLayoutSelection.Type := ReportLayoutSelection.Type::"RDLC (built-in)";
            ReportLayoutSelection."Custom Report Layout Code" := '';
            ReportLayoutSelection.Insert();
        end;
    end;

    local procedure UpdateSalesReceivablesSetup(var OldDefaultPostingDate: Option; DefaultPostingDate: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldDefaultPostingDate := SalesReceivablesSetup."Default Posting Date";
        SalesReceivablesSetup.Validate("Default Posting Date", DefaultPostingDate);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UnapplyCustLedgerEntry(DocumentType: Option; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure VerifyAmtInDtldCustLedgEntries(RowCaption: Text; RowValue: Text; Amount: Decimal)
    begin
        LibraryReportDataset.SetRange(RowCaption, RowValue);
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, RowCaption, RowValue));
        LibraryReportDataset.AssertCurrentRowValueEquals('Amt_DtldCustLedgEntries', Amount);
    end;

    local procedure VerifyAmountInMultipleRows(DocumentNo: Code[20]; Amount: Decimal)
    begin
        VerifyAmtInDtldCustLedgEntries('DocNo_DtldCustLedgEntries', DocumentNo, Amount);
        VerifyAmtInDtldCustLedgEntries('CustBalance', '0', -Amount);
    end;

    local procedure VerifyLineAmtCustomerOrderDetailReport(SalesLineNo: Code[20]; LineAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_SalesLine', SalesLineNo);
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'No_SalesLine', SalesLineNo));
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesOrderAmount', LineAmount);
    end;

    local procedure VerifyTotalLCYOnCustomerSummaryAgingReport(Customer: Record Customer)
    begin
        Customer.CalcFields("Balance (LCY)");
        LibraryReportDataset.SetRange('Total_LCY_Caption', TotalCaptionLbl);
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'Total_LCY_Caption', TotalCaptionLbl));
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalCustBalanceLCY', Customer."Balance (LCY)");
    end;

    local procedure VerifyTotalLCYOnCustomerOrderSummary(ExpectedTotalLCY: Decimal)
    begin
        LibraryReportDataset.SetRange('TotalCaption', ColumnTotalLbl);
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'TotalCaption', ColumnTotalLbl));
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesOrderAmountLCY', Round(ExpectedTotalLCY, 0.01));
    end;

    local procedure VerifyCustomerDetailedAging(DocumentNo: Code[20]; DueDate: Date)
    begin
        LibraryReportDataset.SetRange(DocumentNoLbl, DocumentNo);
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals(DueDateLbl, Format(DueDate));
    end;

    local procedure VerifyCustOrderSummary(SalesLine: Record "Sales Line"; CurrencyFactor: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_Cust', SalesLine."Sell-to Customer No.");
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'No_Cust', SalesLine."Sell-to Customer No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesAmtOnOrderLCY1', 0);
        if CurrencyFactor = 0 then
            CurrencyFactor := 1;
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesOrderAmountLCY', Round(SalesLine."Line Amount" / CurrencyFactor));
    end;

    local procedure VerifyOverDueEntry(PostingDate: Date; Amount: Decimal)
    begin
        LibraryReportDataset.SetRange('OverDueEntries', OverdueEntriesLbl);
        VerifyRemainAmtInCustLedgEntry(PostingDate, Amount);
    end;

    local procedure VerifyRemainAmtInCustLedgEntry(PostingDate: Date; Amount: Decimal)
    begin
        LibraryReportDataset.SetRange('PostDate_CustLedgEntry2', Format(PostingDate));
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, 'PostDate_CustLedgEntry2', Format(PostingDate)));
        LibraryReportDataset.AssertCurrentRowValueEquals('RemainAmt_CustLedgEntry2', Amount);
    end;

    local procedure VerifyCustOrderSummaryTotalValue(CustomerNo: Code[20]; TotalAmount: Decimal)
    var
        RowNo: Integer;
    begin
        LibraryReportValidation.OpenExcelFile;
        RowNo := LibraryReportValidation.FindRowNoFromColumnNoAndValue(2, CustomerNo);
        LibraryReportValidation.VerifyCellValueByRef('K', RowNo, 1, LibraryReportValidation.FormatDecimalValue(TotalAmount));
    end;

    local procedure VerifyAmountOnCustomerOrderSummaryReport(CustomerNo: Code[20]; ExpectedAmount: Decimal)
    var
        RowNo: Integer;
    begin
        LibraryReportValidation.OpenExcelFile;
        RowNo := LibraryReportValidation.FindRowNoFromColumnNoAndValue(2, CustomerNo);
        LibraryReportValidation.VerifyCellValueByRef('E', RowNo, 1, LibraryReportValidation.FormatDecimalValue(ExpectedAmount));
    end;

    local procedure VerifyMultipleCurrencyAmountsOnCustomerOrderSummaryReport(CurrencyCode: array[2] of Code[10]; ExpectedAmount: array[2] of Decimal)
    var
        RowNo: Integer;
        I: Integer;
    begin
        LibraryReportValidation.OpenExcelFile;
        for I := 1 to ArrayLen(CurrencyCode) do begin
            RowNo := LibraryReportValidation.FindRowNoFromColumnNoAndValue(3, CurrencyCode[I]);
            LibraryReportValidation.VerifyCellValueByRef('E', RowNo, 1, LibraryReportValidation.FormatDecimalValue(ExpectedAmount[I]));
        end;
    end;

    local procedure VerifyTotalOnCustomerOrderDetailReport(CustomerNo: Code[20]; ExpectedTotal: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_Customer', CustomerNo);
        LibraryReportDataset.AssertElementWithValueExists('TotalAmt_CurrTotalBuff', ExpectedTotal);
    end;

    local procedure VerifyOutstandingOrdersAndTotalOnCustomerOrderDetailReport(SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ExpectedTotal: Decimal)
    begin
        with LibraryReportDataset do begin
            LoadDataSetFile;
            SetRange('No_Customer', CustomerNo);
            if not GetNextRow then
                Error(StrSubstNo(RowNotFoundErr, 'No_Customer', CustomerNo));
            AssertCurrentRowValueEquals('SalesOrderAmount', SalesLine.Amount);
            GetNextRow;
            SalesLine.Next;
            AssertCurrentRowValueEquals('SalesOrderAmount', SalesLine.Amount);
            AssertElementWithValueExists('TotalAmt_CurrTotalBuff', ExpectedTotal);
        end;
    end;

    local procedure VerifyXMLReport(XmlElementCaption: Text; XmlValue: Text)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange(XmlElementCaption, XmlValue);
        if not LibraryReportDataset.GetNextRow then
            Error(StrSubstNo(RowNotFoundErr, XmlElementCaption, XmlValue));
        LibraryReportDataset.AssertCurrentRowValueEquals(XmlElementCaption, XmlValue);
    end;

    local procedure VerifyCustomerTrialBalanceDCAmounts(CustomerNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_Customer', CustomerNo);
        Assert.IsTrue(
          LibraryReportDataset.GetNextRow,
          StrSubstNo(RowNotFoundErr, 'No_Customer', CustomerNo));
        LibraryReportDataset.AssertCurrentRowValueEquals('PeriodDebitAmt', DebitAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals('PeriodCreditAmt', CreditAmount);
    end;

    local procedure VerifyYourReferenceSalesCrMemo(YourReference: Text[35])
    begin
        LibraryReportValidation.OpenExcelFile;
        LibraryReportValidation.VerifyCellValue(52, 9, YourReference);
    end;

    local procedure VerifyAmountsSalesInvoiceReport(ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal)
    begin
        LibraryReportValidation.OpenExcelFile;
        LibraryReportValidation.VerifyCellValue(106, 48, LibraryReportValidation.FormatDecimalValue(ExpectedAmount)); // Total Amount
        LibraryReportValidation.VerifyCellValue(
          107, 48, LibraryReportValidation.FormatDecimalValue(ExpectedAmountInclVAT - ExpectedAmount)); // Total VAT
        LibraryReportValidation.VerifyCellValue(109, 48, LibraryReportValidation.FormatDecimalValue(ExpectedAmountInclVAT)); // Total Amount Incl. VAT
    end;

    local procedure VerifyCustomerOrderSummarySalesAmount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ExpectedAmount: Decimal;
    begin
        ExpectedAmount := CurrencyExchangeRate.ExchangeAmtFCYToLCY(
            WorkDate, SalesLine."Currency Code", SalesLine."Unit Price", SalesHeader."Currency Factor");

        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_Cust', SalesHeader."Sell-to Customer No.");

        Assert.IsTrue(LibraryReportDataset.GetNextRow, StrSubstNo(RowNotFoundErr, 'No_Cust', SalesHeader."Sell-to Customer No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('SalesOrderAmountLCY', ExpectedAmount);
    end;

    local procedure VerifySalesInvoiceTotalsWithDiscount(SalesLine: Record "Sales Line"; ColumnName: Text; StartingRowNo: Integer)
    begin
        LibraryReportValidation.OpenExcelFile;
        // Subtotal
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, StartingRowNo, 1,
          LibraryReportValidation.FormatDecimalValue(SalesLine."Line Amount"));
        // Discount
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, StartingRowNo + 1, 1,
          LibraryReportValidation.FormatDecimalValue(-SalesLine."Inv. Discount Amount"));
        // Total Exclude VAT
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, StartingRowNo + 2, 1,
          LibraryReportValidation.FormatDecimalValue(SalesLine.Amount));
        // VAT Amount
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, StartingRowNo + 3, 1,
          LibraryReportValidation.FormatDecimalValue(SalesLine."Amount Including VAT" - SalesLine.Amount));
        // Total Include VAT
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, StartingRowNo + 5, 1,
          LibraryReportValidation.FormatDecimalValue(SalesLine."Amount Including VAT"));
    end;

    local procedure VerifyNoOfWorksheetsInExcel(WorksheetsNumber: Integer)
    begin
        LibraryReportValidation.OpenExcelFile;
        Assert.AreEqual(WorksheetsNumber, LibraryReportValidation.CountWorksheets, ExcelCountWorksheetsErr);
    end;

    local procedure VerifyDueMonthsForDueDate(DueDate: Date; DueMonths: Integer)
    begin
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('Cust_Ledger_Entry_Due_Date_', Format(DueDate)) + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('OverDueMonths', DueMonths);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Handler for confirmation messages, always send positive reply.
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ActualMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ActualMessage);
        Assert.AreEqual(Message, Format(ActualMessage), UnexpectedMessageMsg);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SimpleMessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerDetailedAgingRequestPageHandler(var CustomerDetailedAging: TestRequestPage "Customer Detailed Aging")
    var
        CustomerNo: Variant;
        EndDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(EndDate);  // Dequeue variable.
        LibraryVariableStorage.Dequeue(CustomerNo);  // Dequeue variable.
        CustomerDetailedAging."Ending Date".SetValue(EndDate);
        CustomerDetailedAging.ShowOpenEntriesOnly.SetValue(false);  // Setting Show Open Entries Only boolean.
        CustomerDetailedAging.Customer.SetFilter("No.", CustomerNo);
        CustomerDetailedAging.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerListRequestPageHandler(var CustomerList: TestRequestPage "Customer - List")
    begin
        CustomerList.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerSummaryAgingSimpRequestPageHandler(var CustomerSummaryAgingSimp: TestRequestPage "Customer - Summary Aging Simp.")
    var
        CustomerNo: Variant;
        WorkDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(WorkDate);
        LibraryVariableStorage.Dequeue(CustomerNo);
        CustomerSummaryAgingSimp.StartingDate.SetValue(WorkDate);
        CustomerSummaryAgingSimp.Customer.SetFilter("No.", CustomerNo);
        CustomerSummaryAgingSimp.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTopTenListRequestPageHandler(var CustomerTop10List: TestRequestPage "Customer - Top 10 List")
    var
        CustomerNo: Variant;
        ShowType: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowType);
        LibraryVariableStorage.Dequeue(CustomerNo);
        CustomerTop10List.Show.SetValue(ShowType);
        CustomerTop10List.Customer.SetFilter("No.", CustomerNo);
        CustomerTop10List.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTrialBalanceRequestPageHandler(var CustomerTrialBalance: TestRequestPage "Customer - Trial Balance")
    begin
        CustomerTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerOrderDetailRequestPageHandler(var CustomerOrderDetail: TestRequestPage "Customer - Order Detail")
    var
        ShowAmountInLCY: Variant;
        PrintOnlyPerPage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowAmountInLCY);
        LibraryVariableStorage.Dequeue(PrintOnlyPerPage);
        CustomerOrderDetail.ShowAmountsInLCY.SetValue(ShowAmountInLCY);
        CustomerOrderDetail.NewPagePerCustomer.SetValue(PrintOnlyPerPage);
        CustomerOrderDetail.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerOrderSummaryRequestPageHandler(var CustomerOrderSummary: TestRequestPage "Customer - Order Summary")
    var
        StartingDate: Variant;
        ShowAmountLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(ShowAmountLCY);
        CustomerOrderSummary.StartingDate.SetValue(StartingDate);
        CustomerOrderSummary.ShwAmtinLCY.SetValue(ShowAmountLCY);
        CustomerOrderSummary.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerOrderSummaryExcelRequestPageHandler(var CustomerOrderSummary: TestRequestPage "Customer - Order Summary")
    var
        StartingDate: Variant;
        ShowAmountLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(ShowAmountLCY);
        CustomerOrderSummary.StartingDate.SetValue(StartingDate);
        CustomerOrderSummary.ShwAmtinLCY.SetValue(ShowAmountLCY);
        CustomerOrderSummary.SaveAsExcel(LibraryReportValidation.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerRegisterRequestPageHandler(var CustomerRegister: TestRequestPage "Customer Register")
    var
        ShowAmountLCY: Variant;
        EntryNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowAmountLCY);
        LibraryVariableStorage.Dequeue(EntryNo);
        CustomerRegister.ShowAmountsInLCY.SetValue(ShowAmountLCY);
        CustomerRegister."G/L Register".SetFilter("To Entry No.", Format(EntryNo));
        CustomerRegister.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerDetailTrialBalanceRequestPageHandler(var CustomerDetailTrialBal: TestRequestPage "Customer - Detail Trial Bal.")
    var
        ShowAmountLCY: Variant;
        SetPrintOnlyOnePerPage: Variant;
        SetExcludeBalanceOnly: Variant;
        AccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowAmountLCY);
        LibraryVariableStorage.Dequeue(SetPrintOnlyOnePerPage);
        LibraryVariableStorage.Dequeue(SetExcludeBalanceOnly);
        LibraryVariableStorage.Dequeue(AccountNo);
        CustomerDetailTrialBal.ShowAmountsInLCY.SetValue(ShowAmountLCY);
        CustomerDetailTrialBal.NewPageperCustomer.SetValue(SetPrintOnlyOnePerPage);
        CustomerDetailTrialBal.ExcludeCustHaveaBalanceOnly.SetValue(SetExcludeBalanceOnly);
        CustomerDetailTrialBal.Customer.SetFilter("No.", AccountNo);
        CustomerDetailTrialBal.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerDetailTrialBalanceExcelRequestPageHandler(var CustomerDetailTrialBal: TestRequestPage "Customer - Detail Trial Bal.")
    begin
        CustomerDetailTrialBal.ShowAmountsInLCY.SetValue(LibraryVariableStorage.DequeueDecimal);
        CustomerDetailTrialBal.NewPageperCustomer.SetValue(LibraryVariableStorage.DequeueBoolean);
        CustomerDetailTrialBal.ExcludeCustHaveaBalanceOnly.SetValue(LibraryVariableStorage.DequeueBoolean);
        CustomerDetailTrialBal.Customer.SetFilter("No.", LibraryVariableStorage.DequeueText);
        CustomerDetailTrialBal.SaveAsExcel(LibraryReportValidation.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerItemSalesRequestPageHandler(var CustomerItemSales: TestRequestPage "Customer/Item Sales")
    var
        SellToCustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(SellToCustomerNo);
        CustomerItemSales.Customer.SetFilter("No.", SellToCustomerNo);
        CustomerItemSales.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerSalesListRequestPageHandler(var CustomerSalesList: TestRequestPage "Customer - Sales List")
    var
        CustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        CustomerSalesList.Customer.SetFilter("No.", CustomerNo);
        CustomerSalesList.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerDocumentNosRequestPageHandler(var CustomerDocumentNos: TestRequestPage "Customer Document Nos.")
    var
        CustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        CustomerDocumentNos."Cust. Ledger Entry".SetFilter("Customer No.", CustomerNo);
        CustomerDocumentNos.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerSummaryAgingRequestPageHandler(var CustomerSummaryAging: TestRequestPage "Customer - Summary Aging")
    begin
        CustomerSummaryAging.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatementReportRequestPageHandler(var Statement: TestRequestPage Statement)
    begin
        Statement.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName)
    end;

    local procedure VerifySalesInvoiceVATAmountInLCY(DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.GetLastRow;
        VerifySalesReportVATAmount(VATEntry."Document Type"::Invoice, DocumentNo, -1, 'VALVATAmtLCY');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateToDoPageHandler(var CreateTask: Page "Create Task"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentRequestPageHandler(var SalesShipment: TestRequestPage "Sales - Shipment")
    begin
        SalesShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceRequestPageHandler(var SalesInvoice: TestRequestPage "Sales - Invoice")
    begin
        SalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceExcelRequestPageHandler(var SalesInvoice: TestRequestPage "Sales - Invoice")
    begin
        SalesInvoice.SaveAsExcel(LibraryReportValidation.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesCreditMemoExcelRequestPageHandler(var SalesCreditMemo: TestRequestPage "Sales - Credit Memo")
    begin
        SalesCreditMemo.SaveAsExcel(LibraryReportValidation.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesQuoteRequestPageHandler(var SalesQuote: TestRequestPage "Sales - Quote")
    var
        NoOfCopies: Variant;
        InternalInfo: Variant;
        Archived: Variant;
        LogInteraction: Variant;
        Print: Variant;
    begin
        LibraryVariableStorage.Dequeue(NoOfCopies);
        LibraryVariableStorage.Dequeue(InternalInfo);
        LibraryVariableStorage.Dequeue(Archived);
        LibraryVariableStorage.Dequeue(LogInteraction);
        LibraryVariableStorage.Dequeue(Print);

        SalesQuote.NoOfCopies.SetValue(NoOfCopies);
        SalesQuote.ShowInternalInfo.SetValue(InternalInfo);
        SalesQuote.ArchiveDocument.SetValue(Archived);
        SalesQuote.LogInteraction.SetValue(LogInteraction);
        SalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DraftSalesInvoiceRequestPageHandler(var StandardSalesDraftInvoice: TestRequestPage "Standard Sales - Draft Invoice")
    begin
        StandardSalesDraftInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DraftSalesInvoiceExcelRequestPageHandler(var StandardSalesDraftInvoice: TestRequestPage "Standard Sales - Draft Invoice")
    begin
        StandardSalesDraftInvoice.SaveAsExcel(LibraryReportValidation.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesOrderConfRequestPageHandler(var StandardSalesOrderConf: TestRequestPage "Standard Sales - Order Conf.")
    begin
        StandardSalesOrderConf.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesOrderConfExcelRequestPageHandler(var StandardSalesOrderConf: TestRequestPage "Standard Sales - Order Conf.")
    var
        ShowAssemblyComponents: Boolean;
    begin
        ShowAssemblyComponents := LibraryVariableStorage.DequeueBoolean;
        StandardSalesOrderConf.DisplayAsmInformation.SetValue(ShowAssemblyComponents);
        StandardSalesOrderConf.SaveAsExcel(LibraryReportValidation.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OrderConfirmationRequestPageHandler(var OrderConfirmation: TestRequestPage "Order Confirmation")
    begin
        OrderConfirmation.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    local procedure VerifySalesQuoteVATAmountInLCY(DocumentNo: Code[20]; VATAmount: Decimal; VATBaseAmount: Decimal)
    begin
        VerifySalesInvoiceVATAmountInLCY(DocumentNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('VALVATAmtLCY', VATAmount);
        LibraryReportDataset.AssertCurrentRowValueEquals(VALVATBaseLCYTok, VATBaseAmount);
    end;

    local procedure VerifySalesReportVATAmount(DocumentType: Option; DocumentNo: Code[20]; Sign: Integer; VALVATAmountLCYNodeName: Text)
    var
        VATEntry: Record "VAT Entry";
    begin
        with VATEntry do begin
            SetRange(Type, Type::Sale);
            SetRange("Document Type", DocumentType);
            SetRange("Document No.", DocumentNo);
            FindLast;
            LibraryReportDataset.AssertCurrentRowValueEquals(VALVATAmountLCYNodeName, Sign * Amount);
            LibraryReportDataset.AssertCurrentRowValueEquals(VALVATBaseLCYTok, Sign * Base);
        end;
    end;

    local procedure VerifyVATSpecificationLCYForSalesInvoice(VATEntry: Record "VAT Entry"; VATPercent: Decimal)
    begin
        with LibraryReportDataset do begin
            AssertCurrentRowValueEquals(VALVATBaseLCYTok, -VATEntry.Base);
            AssertCurrentRowValueEquals(VALVATAmtLCYTok, -VATEntry.Amount);
            AssertCurrentRowValueEquals(VATPer_VATCounterLCYTok, VATPercent);
            AssertCurrentRowValueEquals(VATIdentifier_VATCounterLCYTok, 'VAT' + Format(VATPercent));
        end;
    end;

    local procedure VerifySalesInvoiceMultipleVATClausesPrinted(VATPostingSetup: array[3] of Record "VAT Posting Setup"; VATClause: array[2] of Record "VAT Clause")
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementTagWithValueExists('VATClauses_Lbl', 'VAT Clause');
        LibraryReportDataset.AssertElementTagWithValueExists('VATIdentifier_Lbl', 'VAT Identifier');

        LibraryReportDataset.AssertElementTagWithValueExists('VATIdentifier_Line', VATPostingSetup[1]."VAT Identifier");
        LibraryReportDataset.AssertElementTagWithValueExists('Description_VATClauseLine', VATClause[1].Description);
        LibraryReportDataset.AssertElementTagWithValueExists('Description2_VATClauseLine', VATClause[1]."Description 2");

        LibraryReportDataset.AssertElementTagWithValueExists('VATIdentifier_Line', VATPostingSetup[2]."VAT Identifier");
        LibraryReportDataset.AssertElementTagWithValueExists('Description_VATClauseLine', VATClause[2].Description);
        LibraryReportDataset.AssertElementTagWithValueExists('Description2_VATClauseLine', VATClause[2]."Description 2");
    end;

    local procedure VerifyExcelWithItemAssemblyComponents(ItemComponentCode: array[3] of Code[20])
    var
        RowNo: Integer;
        ColNo: Integer;
        Index: Integer;
    begin
        LibraryReportValidation.OpenExcelFile;
        for Index := 1 to ArrayLen(ItemComponentCode) do begin
            LibraryReportValidation.FindRowNoColumnNoByValueOnWorksheet(ItemComponentCode[Index], 1, RowNo, ColNo);
            Assert.IsTrue(RowNo > 0, 'Expected to find a row with assembly component');
            Assert.IsTrue(ColNo > 0, 'Expected to find a column with assembly component');
        end;
    end;

    local procedure GetSalesQuoteReportVATAmounts(var VATAmount: Decimal; var VATBaseAmount: Decimal)
    var
        ElementValue: Variant;
    begin
        with LibraryReportDataset do begin
            LoadDataSetFile;
            GetLastRow;

            FindCurrentRowValue(VALVATAmountLCYTok, ElementValue);
            VATAmount := ElementValue;
            FindCurrentRowValue(VALVATBaseLCYTok, ElementValue);
            VATBaseAmount := ElementValue
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    begin
        StandardSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceExcelRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    var
        ShowAssemblyComponents: Boolean;
    begin
        ShowAssemblyComponents := LibraryVariableStorage.DequeueBoolean;
        StandardSalesInvoice.DisplayAsmInformation.SetValue(ShowAssemblyComponents);
        StandardSalesInvoice.SaveAsExcel(LibraryReportValidation.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesQuoteRequestPageHandler(var StandardSalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
        StandardSalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesQuoteADChangeRequestPageHandler(var SalesQuote: TestRequestPage "Sales - Quote")
    begin
        if not LibraryVariableStorage.DequeueBoolean then
            SalesQuote.ArchiveDocument.SetValue(not SalesQuote.ArchiveDocument.AsBoolean);

        LibraryVariableStorage.Enqueue(SalesQuote.ArchiveDocument.Value);
        SalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OrderConfirmationADChangeRequestPageHandler(var OrderConfirmation: TestRequestPage "Order Confirmation")
    begin
        if not LibraryVariableStorage.DequeueBoolean then
            OrderConfirmation.ArchiveDocument.SetValue(not OrderConfirmation.ArchiveDocument.AsBoolean);

        LibraryVariableStorage.Enqueue(OrderConfirmation.ArchiveDocument.Value);
        OrderConfirmation.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderADChangeRequestPageHandler(var BlanketSalesOrder: TestRequestPage "Blanket Sales Order")
    begin
        if not LibraryVariableStorage.DequeueBoolean then
            BlanketSalesOrder.ArchiveDocument.SetValue(not BlanketSalesOrder.ArchiveDocument.AsBoolean);

        LibraryVariableStorage.Enqueue(BlanketSalesOrder.ArchiveDocument.Value);
        BlanketSalesOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesDraftInvoiceADChangeRequestPageHandler(var StandardSalesDraftInvoice: TestRequestPage "Standard Sales - Draft Invoice")
    begin
        if not LibraryVariableStorage.DequeueBoolean then
            StandardSalesDraftInvoice.ArchiveDocument.SetValue(not StandardSalesDraftInvoice.ArchiveDocument.AsBoolean);

        LibraryVariableStorage.Enqueue(StandardSalesDraftInvoice.ArchiveDocument.Value);

        StandardSalesDraftInvoice.Header.SetFilter("No.", '<>''''');
        StandardSalesDraftInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesQuoteADChangeRequestPageHandler(var StandardSalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
        if not LibraryVariableStorage.DequeueBoolean then
            StandardSalesQuote.ArchiveDocument.SetValue(not StandardSalesQuote.ArchiveDocument.AsBoolean);

        LibraryVariableStorage.Enqueue(StandardSalesQuote.ArchiveDocument.Value);

        StandardSalesQuote.Header.SetFilter("No.", '<>''''');
        StandardSalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesOrderConfADChangeRequestPageHandler(var StandardSalesOrderConf: TestRequestPage "Standard Sales - Order Conf.")
    begin
        if not LibraryVariableStorage.DequeueBoolean then
            StandardSalesOrderConf.ArchiveDocument.SetValue(not StandardSalesOrderConf.ArchiveDocument.AsBoolean);

        LibraryVariableStorage.Enqueue(StandardSalesOrderConf.ArchiveDocument.Value);

        StandardSalesOrderConf.Header.SetFilter("No.", '<>''''');
        StandardSalesOrderConf.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesInvoiceRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    begin
        StandardSalesInvoice.DisplayShipmentInformation.SetValue(true);
        StandardSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesCrMemoRequestPageHandler(var StandardSalesCreditMemo: TestRequestPage "Standard Sales - Credit Memo")
    begin
        StandardSalesCreditMemo.DisplayShipmentInformation.SetValue(true);
        StandardSalesCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesQuoteExcelRequestPageHandler(var StandardSalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
        StandardSalesQuote.SaveAsExcel(LibraryReportValidation.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesDraftInvoiceExcelRequestPageHandler(var StandardSalesDraftInvoice: TestRequestPage "Standard Sales - Draft Invoice")
    begin
        StandardSalesDraftInvoice.SaveAsExcel(LibraryReportValidation.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesInvoiceExcelRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    begin
        StandardSalesInvoice.SaveAsExcel(LibraryReportValidation.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesCreditMemoExcelRequestPageHandler(var StandardSalesCreditMemo: TestRequestPage "Standard Sales - Credit Memo")
    begin
        StandardSalesCreditMemo.SaveAsExcel(LibraryReportValidation.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsRequestPageHandler(var SalesStatistics: TestRequestPage "Sales Statistics")
    begin
        SalesStatistics.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

