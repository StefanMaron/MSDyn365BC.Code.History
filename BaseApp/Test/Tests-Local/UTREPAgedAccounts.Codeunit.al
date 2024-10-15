codeunit 141075 "UT REP Aged Accounts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report] [Aged Accounts]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        FileManagement: Codeunit "File Management";
        CurrencyCodeCap: Label 'GetCurrencyCode_CurrencyCode_';
        EntryAmountCap: Label 'EntryAmount_5_';

    [Test]
    [HandlerFunctions('AgedAccountsPayableBackdatingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecVendPostingDateAgedAccPayBackDating()
    var
        Vendor: Record Vendor;
        UseAgingDate: Option "Posting Date";
        UseCurrency: Option "Document Currency";
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] validate Vendor - OnAfterGetRecord Trigger of Report - 17117 with Use Aging Date Posting Date and Use Currency Document Currency.

        // Setup and Exercise.
        Initialize;
        Amount :=
          CreateVendLedgEntriesAndRunAgedAccPayBackDatingRpt(
            CreateCurrency, true, Vendor.Blocked::All, UseAgingDate::"Posting Date", UseCurrency::"Document Currency", 0);  // Value 0 used for Date Expression and True for Print Entry Details.

        // Verify.
        VerifyValuesOnAgedAccountsBackdatingReport(GetLCYCodeFromGeneralLedgerSetup, Amount);
    end;

    [Test]
    [HandlerFunctions('AgedAccountsPayableBackdatingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecVendDueDateAgedAccPayBackDating()
    var
        Vendor: Record Vendor;
        UseAgingDate: Option "Posting Date","Document Date","Due Date";
        UseCurrency: Option "Document Currency","Vendor Currency",LCY;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] validate Vendor - OnAfterGetRecord Trigger of Report - 17117 with Use Aging Date Due Date and Use Currency LCY.
        Initialize;
        OnAfterGetRecVendAgedAccPayBackDating(
          CreateCurrency, GetLCYCodeFromGeneralLedgerSetup, true, Vendor.Blocked::" ", UseAgingDate::"Due Date", UseCurrency::LCY, 0);  // True for Print Entry Details and 0 used for Date Expression.
    end;

    [Test]
    [HandlerFunctions('AgedAccountsPayableBackdatingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecVendWithCurrAgedAccPayBackDating()
    var
        Vendor: Record Vendor;
        CurrencyCode: Code[10];
        UseAgingDate: Option "Posting Date","Document Date";
        UseCurrency: Option "Document Currency","Vendor Currency";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] validate Vendor - OnAfterGetRecord Trigger of Report - 17117 with Currency Code.
        Initialize;
        CurrencyCode := CreateCurrency;
        OnAfterGetRecVendAgedAccPayBackDating(
          CurrencyCode, CurrencyCode, false, Vendor.Blocked::Payment, UseAgingDate::"Document Date", UseCurrency::"Vendor Currency",
          LibraryRandom.RandInt(5));  // False for Print Entry Details and Random value for Date Expression.
    end;

    [Test]
    [HandlerFunctions('AgedAccountsPayableBackdatingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecVendWithoutCurrAgedAccPayBackDating()
    var
        Vendor: Record Vendor;
        UseAgingDate: Option "Posting Date","Document Date";
        UseCurrency: Option "Document Currency","Vendor Currency";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] validate Vendor Ledger Entry - OnAfterGetRecord Trigger of Report - 17117 without Currency Code.
        Initialize;
        OnAfterGetRecVendAgedAccPayBackDating(
          '', GetLCYCodeFromGeneralLedgerSetup, false, Vendor.Blocked::Payment, UseAgingDate::"Document Date", UseCurrency::"Vendor Currency",
          LibraryRandom.RandInt(5));  // Blank used for Currency Code, False for Print Entry Details and Random value for Date Expression.
    end;

    local procedure OnAfterGetRecVendAgedAccPayBackDating(CurrencyCode: Code[10]; ExpectedCurrencyCode: Code[10]; PrintEntryDetails: Boolean; Blocked: Enum "Vendor Blocked"; UseAgingDate: Option; UseCurrency: Option; NoOfDays: Integer)
    begin
        // Setup and Exercise.
        CreateVendLedgEntriesAndRunAgedAccPayBackDatingRpt(CurrencyCode, PrintEntryDetails, Blocked, UseAgingDate, UseCurrency, NoOfDays);

        // Verify.
        VerifyValuesOnAgedAccountsBackdatingReport(ExpectedCurrencyCode, 0);  // Value 0 required for Amount.
    end;

    [Test]
    [HandlerFunctions('AgedAccountsReceivableBackdatingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecCustPostingDateAgedAccRecBackDating()
    var
        Customer: Record Customer;
        UseAgingDate: Option "Posting Date";
        UseCurrency: Option "Document Currency";
        Amount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] validate Customer - OnAfterGetRecord Trigger of Report - 17116 with Use Aging Date Posting Date and Use Currency Document Currency.

        // Setup and Exercise.
        Initialize;
        Amount :=
          CreateCustLedgEntriesAndRunAgedAccRecBackDatingRpt(
            CreateCurrency, true, Customer.Blocked::All, UseAgingDate::"Posting Date", UseCurrency::"Document Currency", 0, 0);  // Value 0 used for Date Expression and Credit Limit LCY, True for Print Entry Details.

        // Verify.
        VerifyValuesOnAgedAccountsBackdatingReport(GetLCYCodeFromGeneralLedgerSetup, Amount);
    end;

    [Test]
    [HandlerFunctions('AgedAccountsReceivableBackdatingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecCustDueDateAgedAccRecBackDating()
    var
        Customer: Record Customer;
        UseAgingDate: Option "Posting Date","Document Date","Due Date";
        UseCurrency: Option "Document Currency","Customer Currency",LCY;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] validate Customer - OnAfterGetRecord Trigger of Report - 17116 with Use Aging Date Due Date and Use Currency LCY.
        Initialize;
        OnAfterGetRecCustAgedAccRecBackDating(
          CreateCurrency, GetLCYCodeFromGeneralLedgerSetup, true, Customer.Blocked::" ", UseAgingDate::"Due Date", UseCurrency::LCY, 0);  // Value 0 used for Date Expression, True for Print Entry Details.
    end;

    [Test]
    [HandlerFunctions('AgedAccountsReceivableBackdatingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecCustWithCurrAgedAccRecBackDating()
    var
        Customer: Record Customer;
        CurrencyCode: Code[10];
        UseAgingDate: Option "Posting Date","Document Date";
        UseCurrency: Option "Document Currency","Customer Currency";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] validate Customer - OnAfterGetRecord Trigger of Report - 17116 with Currency Code.
        Initialize;
        CurrencyCode := CreateCurrency;
        OnAfterGetRecCustAgedAccRecBackDating(
          CurrencyCode, CurrencyCode, false, Customer.Blocked::Ship, UseAgingDate::"Document Date", UseCurrency::"Customer Currency",
          LibraryRandom.RandInt(5));  // Random value used for Date Expression, False for Print Entry Details.
    end;

    [Test]
    [HandlerFunctions('AgedAccountsReceivableBackdatingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecCustWithoutCurrAgedAccRecBackDating()
    var
        Customer: Record Customer;
        UseAgingDate: Option "Posting Date","Document Date";
        UseCurrency: Option "Document Currency","Customer Currency";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] validate Customer - OnAfterGetRecord Trigger of Report - 17116 without Currency Code.
        Initialize;
        OnAfterGetRecCustAgedAccRecBackDating(
          '', GetLCYCodeFromGeneralLedgerSetup, false, Customer.Blocked::Invoice, UseAgingDate::"Document Date",
          UseCurrency::"Customer Currency", LibraryRandom.RandInt(5));  // Blank for Currency Code, Random value used for Date Expression, False for Print Entry Details.
    end;

    local procedure OnAfterGetRecCustAgedAccRecBackDating(CurrencyCode: Code[10]; ExpectedCurrencyCode: Code[10]; PrintEntryDetails: Boolean; Blocked: Enum "Customer Blocked"; UseAgingDate: Option; UseCurrency: Option; NoOfDays: Integer)
    begin
        // Setup and Exercise.
        CreateCustLedgEntriesAndRunAgedAccRecBackDatingRpt(
          CurrencyCode, PrintEntryDetails, Blocked, UseAgingDate, UseCurrency, NoOfDays, LibraryRandom.RandDecInRange(50, 100, 2));  // Random value used for Credit Limit LCY.

        // Verify.
        VerifyValuesOnAgedAccountsBackdatingReport(ExpectedCurrencyCode, 0);  // Value 0 required for Amount.
    end;

    [Test]
    [HandlerFunctions('AgedAccountsReceivableBackdatingAsPDFRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintAgedAccRecBackDatingAsPDF()
    var
        Customer: Record Customer;
        UseAgingDate: Option "Posting Date";
        UseCurrency: Option "Document Currency";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 333888] Report "Aged Acc. Rec. (BackDating)" can be printed without RDLC rendering errors
        Initialize;

        // [WHEN] Report "Aged Acc. Rec. (BackDating)" is being printed to PDF
        CreateCustLedgEntriesAndRunAgedAccRecBackDatingRpt(
          CreateCurrency, true, Customer.Blocked::All, UseAgingDate::"Posting Date", UseCurrency::"Document Currency", 0, 0);
        // [THEN] No RDLC rendering errors
    end;

    [Test]
    [HandlerFunctions('AgedAccountsPayableBackdatingAdPDFRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintAgedPayRecBackDatingAsPDF()
    var
        Vendor: Record Vendor;
        UseAgingDate: Option "Posting Date";
        UseCurrency: Option "Document Currency";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 333888] Report "Aged Acc. Pay. (BackDating)" can be printed without RDLC rendering errors
        Initialize;

        // [WHEN] Report "Aged Acc. Rec. (BackDating)" is being printed to PDF
        CreateVendLedgEntriesAndRunAgedAccPayBackDatingRpt(
          CreateCurrency, true, Vendor.Blocked::All, UseAgingDate::"Posting Date", UseCurrency::"Document Currency", 0);  // Value 0 used for Date Expression and True for Print Entry Details.

        // [THEN] No RDLC rendering errors
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10;
        Currency.Insert();
        CreateCurrencyExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCurrencyExchangeRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate."Currency Code" := CurrencyCode;
        CurrencyExchangeRate."Starting Date" := WorkDate;
        CurrencyExchangeRate."Exchange Rate Amount" := LibraryRandom.RandDec(10, 2);
        CurrencyExchangeRate."Relational Exch. Rate Amount" := LibraryRandom.RandDec(10, 2);
        CurrencyExchangeRate.Insert();
    end;

    local procedure CreateCustomer(CurrencyCode: Code[10]; Blocked: Enum "Customer Blocked"; CreditLimitLCY: Decimal): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode;
        Customer.Blocked := Blocked;
        Customer."Currency Code" := CurrencyCode;
        Customer."Net Change (LCY)" := LibraryRandom.RandDecInRange(10, 50, 2);
        Customer."Credit Limit (LCY)" := CreditLimitLCY;
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateCustLedgEntriesAndRunAgedAccRecBackDatingRpt(CurrencyCode: Code[10]; PrintEntryDetails: Boolean; Blocked: Enum "Customer Blocked"; UseAgingDate: Option; UseCurrency: Option; NoOfDays: Integer; CreditLimitLCY: Decimal) Amount: Decimal
    var
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Setup.
        CreateCustomerLedgerEntry(CustomerLedgerEntry, CurrencyCode, Blocked, CreditLimitLCY);
        Amount :=
          CreateDetailedCustomerLedgerEntry(
            CustomerLedgerEntry, CalcDate('<' + Format(NoOfDays) + 'D>', CustomerLedgerEntry."Posting Date"));
        EnqueueValuesForMiscellaneousHandler(CustomerLedgerEntry."Customer No.", PrintEntryDetails, UseAgingDate, UseCurrency);  // Enqueue values for AgedAccountsReceivableBackdatingRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Aged Acc. Rec. (BackDating)");  // Opens AgedAccountsReceivableBackdatingRequestPageHandler.
    end;

    local procedure CreateCustomerLedgerEntry(var CustomerLedgerEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10]; Blocked: Enum "Customer Blocked"; CreditLimitLCY: Decimal)
    var
        CustomerLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        CustomerLedgerEntry2.FindLast;
        CustomerLedgerEntry."Entry No." := CustomerLedgerEntry2."Entry No." + 1;
        CustomerLedgerEntry."Customer No." := CreateCustomer(CurrencyCode, Blocked, CreditLimitLCY);
        CustomerLedgerEntry."Posting Date" := WorkDate;
        CustomerLedgerEntry.Open := true;
        CustomerLedgerEntry.Insert();
    end;

    local procedure CreateDetailedCustomerLedgerEntry(CustomerLedgerEntry: Record "Cust. Ledger Entry"; PostingDate: Date): Decimal
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry2.FindLast;
        DetailedCustLedgEntry."Entry No." := DetailedCustLedgEntry2."Entry No." + 1;
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::Application;
        DetailedCustLedgEntry."Customer No." := CustomerLedgerEntry."Customer No.";
        DetailedCustLedgEntry."Posting Date" := PostingDate;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustomerLedgerEntry."Entry No.";
        DetailedCustLedgEntry.Amount := LibraryRandom.RandDec(100, 2);
        DetailedCustLedgEntry.Insert(true);
        exit(DetailedCustLedgEntry.Amount);
    end;

    local procedure CreateDetailedVendorLedgerEntry(VendorLedgerEntry: Record "Vendor Ledger Entry"; PostingDate: Date): Decimal
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry2.FindLast;
        DetailedVendorLedgEntry."Entry No." := DetailedVendorLedgEntry2."Entry No." + 1;
        DetailedVendorLedgEntry."Entry Type" := DetailedVendorLedgEntry."Entry Type"::Application;
        DetailedVendorLedgEntry."Vendor No." := VendorLedgerEntry."Vendor No.";
        DetailedVendorLedgEntry."Posting Date" := PostingDate;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        DetailedVendorLedgEntry.Amount := LibraryRandom.RandDec(100, 2);
        DetailedVendorLedgEntry.Insert(true);
        exit(DetailedVendorLedgEntry.Amount);
    end;

    local procedure CreateVendLedgEntriesAndRunAgedAccPayBackDatingRpt(CurrencyCode: Code[10]; PrintEntryDetails: Boolean; Blocked: Enum "Vendor Blocked"; UseAgingDate: Option; UseCurrency: Option; NoOfDays: Integer) Amount: Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Setup.
        CreateVendorLedgerEntry(VendorLedgerEntry, CurrencyCode, Blocked);
        Amount :=
          CreateDetailedVendorLedgerEntry(VendorLedgerEntry, CalcDate('<' + Format(NoOfDays) + 'D>', VendorLedgerEntry."Posting Date"));
        EnqueueValuesForMiscellaneousHandler(VendorLedgerEntry."Vendor No.", PrintEntryDetails, UseAgingDate, UseCurrency);  // Enqueue values for AgedAccountsPayableBackdatingRequestPageHandler.

        // Exercise:
        REPORT.Run(REPORT::"Aged Acc. Pay. (BackDating)");  // Opens AgedAccountsPayableBackdatingRequestPageHandler.
    end;

    local procedure CreateVendor(CurrencyCode: Code[10]; Blocked: Enum "Vendor Blocked"): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode;
        Vendor.Blocked := Blocked;
        Vendor."Currency Code" := CurrencyCode;
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; CurrencyCode: Code[10]; Blocked: Enum "Vendor Blocked")
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry2.FindLast;
        VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;
        VendorLedgerEntry."Vendor No." := CreateVendor(CurrencyCode, Blocked);
        VendorLedgerEntry."Posting Date" := WorkDate;
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert();
    end;

    local procedure EnqueueValuesForMiscellaneousHandler(No: Code[20]; PrintEntryDetails: Boolean; UseAgingDate: Option; UseCurrency: Option)
    begin
        LibraryVariableStorage.Enqueue(No);
        LibraryVariableStorage.Enqueue(PrintEntryDetails);
        LibraryVariableStorage.Enqueue(UseAgingDate);
        LibraryVariableStorage.Enqueue(UseCurrency);
    end;

    local procedure GetLCYCodeFromGeneralLedgerSetup(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."LCY Code");
    end;

    local procedure VerifyValuesOnAgedAccountsBackdatingReport(CurrencyCode: Code[10]; EntryAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(CurrencyCodeCap, CurrencyCode);
        LibraryReportDataset.AssertElementWithValueExists(EntryAmountCap, EntryAmount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AgedAccountsPayableBackdatingRequestPageHandler(var AgedAccPayBackDating: TestRequestPage "Aged Acc. Pay. (BackDating)")
    var
        No: Variant;
        PrintEntryDetails: Variant;
        UseAgingDate: Variant;
        UseCurrency: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(PrintEntryDetails);
        LibraryVariableStorage.Dequeue(UseAgingDate);
        LibraryVariableStorage.Dequeue(UseCurrency);
        AgedAccPayBackDating.Vendor.SetFilter("No.", No);
        AgedAccPayBackDating.AgedAsOf.SetValue(WorkDate);
        AgedAccPayBackDating.UseAgingDate.SetValue(UseAgingDate);
        AgedAccPayBackDating.UseCurrency.SetValue(UseCurrency);
        AgedAccPayBackDating.PrintTotalsPerCurrency.SetValue(true);
        AgedAccPayBackDating.PrintAccountDetails.SetValue(true);
        AgedAccPayBackDating.PrintEntryDetails.SetValue(PrintEntryDetails);
        AgedAccPayBackDating.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AgedAccountsReceivableBackdatingRequestPageHandler(var AgedAccRecBackDating: TestRequestPage "Aged Acc. Rec. (BackDating)")
    var
        No: Variant;
        PrintEntryDetails: Variant;
        UseAgingDate: Variant;
        UseCurrency: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(PrintEntryDetails);
        LibraryVariableStorage.Dequeue(UseAgingDate);
        LibraryVariableStorage.Dequeue(UseCurrency);
        AgedAccRecBackDating.Customer.SetFilter("No.", No);
        AgedAccRecBackDating.AgedAsOf.SetValue(WorkDate);
        AgedAccRecBackDating.UseAgingDate.SetValue(UseAgingDate);
        AgedAccRecBackDating.UseCurrency.SetValue(UseCurrency);
        AgedAccRecBackDating.PrintTotalsPerCurrency.SetValue(true);
        AgedAccRecBackDating.PrintAccountDetails.SetValue(true);
        AgedAccRecBackDating.PrintEntryDetails.SetValue(PrintEntryDetails);
        AgedAccRecBackDating.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AgedAccountsReceivableBackdatingAsPDFRequestPageHandler(var AgedAccRecBackDating: TestRequestPage "Aged Acc. Rec. (BackDating)")
    var
        No: Variant;
        PrintEntryDetails: Variant;
        UseAgingDate: Variant;
        UseCurrency: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(PrintEntryDetails);
        LibraryVariableStorage.Dequeue(UseAgingDate);
        LibraryVariableStorage.Dequeue(UseCurrency);
        AgedAccRecBackDating.Customer.SetFilter("No.", No);
        AgedAccRecBackDating.AgedAsOf.SetValue(WorkDate);
        AgedAccRecBackDating.UseAgingDate.SetValue(UseAgingDate);
        AgedAccRecBackDating.UseCurrency.SetValue(UseCurrency);
        AgedAccRecBackDating.PrintTotalsPerCurrency.SetValue(true);
        AgedAccRecBackDating.PrintAccountDetails.SetValue(true);
        AgedAccRecBackDating.PrintEntryDetails.SetValue(PrintEntryDetails);
        AgedAccRecBackDating.SaveAsPdf(FileManagement.ServerTempFileName('.pdf'));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AgedAccountsPayableBackdatingAdPDFRequestPageHandler(var AgedAccPayBackDating: TestRequestPage "Aged Acc. Pay. (BackDating)")
    var
        No: Variant;
        PrintEntryDetails: Variant;
        UseAgingDate: Variant;
        UseCurrency: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(PrintEntryDetails);
        LibraryVariableStorage.Dequeue(UseAgingDate);
        LibraryVariableStorage.Dequeue(UseCurrency);
        AgedAccPayBackDating.Vendor.SetFilter("No.", No);
        AgedAccPayBackDating.AgedAsOf.SetValue(WorkDate);
        AgedAccPayBackDating.UseAgingDate.SetValue(UseAgingDate);
        AgedAccPayBackDating.UseCurrency.SetValue(UseCurrency);
        AgedAccPayBackDating.PrintTotalsPerCurrency.SetValue(true);
        AgedAccPayBackDating.PrintAccountDetails.SetValue(true);
        AgedAccPayBackDating.PrintEntryDetails.SetValue(PrintEntryDetails);
        AgedAccPayBackDating.SaveAsPdf(FileManagement.ServerTempFileName('.pdf'));
    end;
}

