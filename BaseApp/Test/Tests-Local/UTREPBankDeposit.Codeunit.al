codeunit 141009 "UT REP Bank Deposit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Deposit] [Reports]
    end;

    var
        LibraryReportDataSet: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        PostedDepositLineAmount: Label 'Posted_Deposit_Line_Amount';
        PostedDepositLineAccountTypeCap: Label 'Posted_Deposit_Line__Account_Type_';
        PostedDepositLineAccountNoCap: Label 'Posted_Deposit_Line__Account_No__';
        AmountCap: Label 'Amount';
        GenJournalLineAccountTypeCap: Label 'Gen__Journal_Line__Account_Type_';
        GenJournalLineDocumentTypeCap: Label 'Gen__Journal_Line__Document_Type_';
        AmountDueCap: Label 'AmountDue';
        DimensionCap: Label 'Dim1Number';
        GenJournalLineAppliesToIDCap: Label 'Gen__Journal_Line_Applies_to_ID';
        DimSetEntryDimensionCodeCap: Label 'DimSetEntry__Dimension_Code_';
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [HandlerFunctions('DepositRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustLedgerEntryDeposit()
    var
        PostedDepositLine: Record "Posted Deposit Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Purpose of the test is to validate Posted Deposit Line - OnAfterGetRecord of the Report ID: 10403, Deposit with Cust. Ledger Entry.
        // Setup.
        Initialize;
        CreatePostedDeposit(PostedDepositLine, PostedDepositLine."Account Type"::Customer, CreateCustomer);
        CreateCustomerLedgerEntry(CustLedgerEntry, PostedDepositLine."Document No.", PostedDepositLine."Account No.");
        UpdateEntryNoPostedDepositLine(PostedDepositLine, CustLedgerEntry."Entry No.");
        CreateDetailedCustomerLedgerEntry(CustLedgerEntry."Entry No.", PostedDepositLine."Account No.");

        // Enqueue values for use in DepositRequestPageHandler.
        LibraryVariableStorage.Enqueue(PostedDepositLine."Deposit No.");
        LibraryVariableStorage.Enqueue(true);  // Print Application - TRUE.

        // Exercise.
        Commit;  // Commit required for explicit commit used in Codeunit ID: 10143, Deposit-Printed.
        REPORT.Run(REPORT::Deposit);

        // Verify: Verify the Account No and Sum Amount after running Deposit Report.
        LibraryReportDataSet.LoadDataSetFile;
        LibraryReportDataSet.AssertElementWithValueExists(PostedDepositLineAccountTypeCap, Format(PostedDepositLine."Account Type"::Customer));
        LibraryReportDataSet.AssertElementWithValueExists(PostedDepositLineAccountNoCap, PostedDepositLine."Account No.");
        LibraryReportDataSet.AssertElementWithValueExists(PostedDepositLineAmount, PostedDepositLine.Amount);
    end;

    [Test]
    [HandlerFunctions('DepositRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendLedgerEntryDeposit()
    var
        PostedDepositLine: Record "Posted Deposit Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Purpose of the test is to validate Posted Deposit Line - OnAfterGetRecord of the Report ID: 10403, Deposit with Vendor Ledger Entry.
        // Setup.
        Initialize;
        CreatePostedDeposit(PostedDepositLine, PostedDepositLine."Account Type"::Vendor, CreateVendor);
        CreateVendorLedgerEntry(VendorLedgerEntry, PostedDepositLine."Document No.", PostedDepositLine."Account No.");
        UpdateEntryNoPostedDepositLine(PostedDepositLine, VendorLedgerEntry."Entry No.");
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", PostedDepositLine."Account No.");

        // Enqueue values for use in DepositRequestPageHandler.
        LibraryVariableStorage.Enqueue(PostedDepositLine."Deposit No.");
        LibraryVariableStorage.Enqueue(false);  // Print Application - FALSE.

        // Exercise.
        Commit;  // Commit required for explicit commit used in Codeunit ID: 10143, Deposit-Printed.
        REPORT.Run(REPORT::Deposit);

        // Verify: Verify the Account No and Sum Amount after running Deposit Report.
        LibraryReportDataSet.LoadDataSetFile;
        LibraryReportDataSet.AssertElementWithValueExists(PostedDepositLineAccountTypeCap, Format(PostedDepositLine."Account Type"::Vendor));
        LibraryReportDataSet.AssertElementWithValueExists(PostedDepositLineAccountNoCap, PostedDepositLine."Account No.");
        LibraryReportDataSet.AssertElementWithValueExists(PostedDepositLineAmount, PostedDepositLine.Amount);
    end;

    [Test]
    [HandlerFunctions('DepositRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBankAccountDeposit()
    var
        PostedDepositHeader: Record "Posted Deposit Header";
        PostedDepositLine: Record "Posted Deposit Line";
    begin
        // Purpose of the test is to validate Posted Deposit Line - OnAfterGetRecord of the Report ID: 10403, Deposit with Account Type Bank Account.
        // Setup.
        Initialize;
        CreatePostedDeposit(PostedDepositLine, PostedDepositLine."Account Type"::"Bank Account", CreateBankAccount);

        // Enqueue values for use in DepositRequestPageHandler.
        LibraryVariableStorage.Enqueue(PostedDepositHeader."No.");
        LibraryVariableStorage.Enqueue(true);  // Print Application - TRUE.

        // Exercise.
        Commit;  // Commit required for explicit commit used in Codeunit ID: 10143, Deposit-Printed.
        REPORT.Run(REPORT::Deposit);

        // Verify: Verify the Account No and Account Type after running Deposit Report.
        LibraryReportDataSet.LoadDataSetFile;
        LibraryReportDataSet.AssertElementWithValueExists(PostedDepositLineAccountTypeCap, Format(PostedDepositLine."Account Type"::"Bank Account"));
        LibraryReportDataSet.AssertElementWithValueExists(PostedDepositLineAccountNoCap, PostedDepositLine."Account No.");
    end;

    [Test]
    [HandlerFunctions('DepositRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLAccountDeposit()
    var
        PostedDepositLine: Record "Posted Deposit Line";
    begin
        // Purpose of the test is to validate Posted Deposit Line - OnAfterGetRecord of the Report ID: 10403, Deposit with Account Type GL Account.
        // Setup.
        Initialize;
        CreatePostedDeposit(PostedDepositLine, PostedDepositLine."Account Type"::"G/L Account", CreateGLAccount);

        // Enqueue values for use in DepositRequestPageHandler.
        LibraryVariableStorage.Enqueue(PostedDepositLine."Deposit No.");
        LibraryVariableStorage.Enqueue(true);  // Print Application - TRUE.

        // Exercise.
        Commit; // Commit required for explicit commit used in Codeunit ID: 10143, Deposit-Printed.
        REPORT.Run(REPORT::Deposit);

        // Verify: Verify the Account No and Account Type after running Deposit Report.
        LibraryReportDataSet.LoadDataSetFile;
        LibraryReportDataSet.AssertElementWithValueExists(PostedDepositLineAccountTypeCap, Format(PostedDepositLine."Account Type"::"G/L Account"));
        LibraryReportDataSet.AssertElementWithValueExists(PostedDepositLineAccountNoCap, PostedDepositLine."Account No.");
    end;

    [Test]
    [HandlerFunctions('DepositTestReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJournalLineBlankICDepositTestReport()
    var
        DepositHeader: Record "Deposit Header";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Gen. Journal Line - OnAfterGetRecord of the Report ID: 10402, Deposit Test Report with Account Type IC Partner.
        // Setup.
        Initialize;
        CreateDepositHeader(DepositHeader);
        CreateGenJournalLine(GenJournalLine, DepositHeader, GenJournalLine."Account Type"::"IC Partner", '');  // Blank IC Partner Code.
        LibraryVariableStorage.Enqueue(DepositHeader."No.");  // Enqueue value for use in DepositTestReportRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Deposit Test Report");

        // Verify: Verify the Document Type, Account Type and Amount after running Deposit Test Report.
        LibraryReportDataSet.LoadDataSetFile;
        LibraryReportDataSet.AssertElementWithValueExists(GenJournalLineAccountTypeCap, Format(GenJournalLine."Account Type"::"IC Partner"));
        LibraryReportDataSet.AssertElementWithValueExists(GenJournalLineDocumentTypeCap, Format(GenJournalLine."Document Type"::Payment));
        LibraryReportDataSet.AssertElementWithValueExists(AmountCap, DepositHeader."Total Deposit Amount");
    end;

    [Test]
    [HandlerFunctions('DepositTestReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJournalLineTypeICDepositTestReport()
    var
        DepositHeader: Record "Deposit Header";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate Gen. Journal Line - OnAfterGetRecord of the Report ID: 10402, Deposit Test Report with Account Type IC Partner.
        // Setup.
        Initialize;
        CreateDepositHeader(DepositHeader);
        CreateGenJournalLine(GenJournalLine, DepositHeader, GenJournalLine."Account Type"::"IC Partner", CreateICPartner);
        LibraryVariableStorage.Enqueue(DepositHeader."No.");  // Enqueue value for use in DepositTestReportRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Deposit Test Report");

        // Verify: Verify the Document Type, Account Type and Amount after running Deposit Test Report.
        LibraryReportDataSet.LoadDataSetFile;
        LibraryReportDataSet.AssertElementWithValueExists(GenJournalLineAccountTypeCap, Format(GenJournalLine."Account Type"::"IC Partner"));
        LibraryReportDataSet.AssertElementWithValueExists(GenJournalLineDocumentTypeCap, Format(GenJournalLine."Document Type"::Payment));
        LibraryReportDataSet.AssertElementWithValueExists(AmountCap, DepositHeader."Total Deposit Amount");
    end;

    [Test]
    [HandlerFunctions('DepositTestReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendLedgerEntryDepositTestReport()
    var
        DepositHeader: Record "Deposit Header";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Purpose of the test is to validate Vendor Ledger Entry - OnAfterGetRecord of the Report ID: 10402, Deposit Test Report with Account Type Vendor.
        // Setup.
        Initialize;
        CreateDepositHeader(DepositHeader);
        CreateGenJournalLine(GenJournalLine, DepositHeader, GenJournalLine."Account Type"::Vendor, CreateVendor);
        UpdateApplyToDocGenJournalLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(DepositHeader."No.");  // Enqueue value for use in DepositTestReportRequestPageHandler.
        CreateVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document No.", GenJournalLine."Account No.");
        UpdateApplyToDocVendorLedgerEntry(VendorLedgerEntry, GenJournalLine);
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", GenJournalLine."Account No.");

        // Exercise.
        REPORT.Run(REPORT::"Deposit Test Report");

        // Verify: Verify the Document Type, Account Type, Amount and Amount Due after running Deposit Test Report.
        LibraryReportDataSet.LoadDataSetFile;
        VendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryReportDataSet.AssertElementWithValueExists(GenJournalLineAccountTypeCap, Format(GenJournalLine."Account Type"::Vendor));
        LibraryReportDataSet.AssertElementWithValueExists(GenJournalLineDocumentTypeCap, Format(GenJournalLine."Document Type"::Payment));
        LibraryReportDataSet.AssertElementWithValueExists(AmountCap, DepositHeader."Total Deposit Amount");
        LibraryReportDataSet.AssertElementWithValueExists(AmountDueCap, VendorLedgerEntry."Remaining Amount");
    end;

    [Test]
    [HandlerFunctions('DepositTestReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustLedgerEntryDepositTestReport()
    var
        DepositHeader: Record "Deposit Header";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Purpose of the test is to validate Cust. Ledger Entry - OnAfterGetRecord of the Report ID: 10402, Deposit Test Report with Account Type Customer.
        // Setup.
        Initialize;
        CreateDepositHeader(DepositHeader);
        CreateGenJournalLine(GenJournalLine, DepositHeader, GenJournalLine."Account Type"::Customer, CreateCustomer);
        UpdateApplyToDocGenJournalLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(DepositHeader."No.");  // Enqueue value for use in DepositTestReportRequestPageHandler.
        CreateCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document No.", GenJournalLine."Account No.");
        UpdateApplyToDocCustomerLedgerEntry(CustLedgerEntry, GenJournalLine);
        CreateDetailedCustomerLedgerEntry(CustLedgerEntry."Entry No.", GenJournalLine."Account No.");

        // Exercise.
        REPORT.Run(REPORT::"Deposit Test Report");

        // Verify: Verify the Document Type, Account Type, Amount and Amount Due after running Deposit Test Report.
        LibraryReportDataSet.LoadDataSetFile;
        CustLedgerEntry.CalcFields("Remaining Amount");
        LibraryReportDataSet.AssertElementWithValueExists(GenJournalLineAccountTypeCap, Format(GenJournalLine."Account Type"::Customer));
        LibraryReportDataSet.AssertElementWithValueExists(GenJournalLineDocumentTypeCap, Format(GenJournalLine."Document Type"::Payment));
        LibraryReportDataSet.AssertElementWithValueExists(AmountCap, DepositHeader."Total Deposit Amount");
        LibraryReportDataSet.AssertElementWithValueExists(AmountDueCap, CustLedgerEntry."Remaining Amount");
    end;

    [Test]
    [HandlerFunctions('DepositTestReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordApplyCustLedgerDepositTestReport()
    var
        DepositHeader: Record "Deposit Header";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Purpose of the test is to validate Cust. Ledger Entry - OnAfterGetRecord of the Report ID: 10402, Deposit Test Report with Applies To ID.
        // Setup.
        Initialize;
        CreateDepositHeader(DepositHeader);
        CreateGenJournalLine(GenJournalLine, DepositHeader, GenJournalLine."Account Type"::Customer, CreateCustomer);
        LibraryVariableStorage.Enqueue(DepositHeader."No.");  // Enqueue value for use in DepositTestReportRequestPageHandler.
        CreateCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document No.", GenJournalLine."Account No.");
        CustLedgerEntry."Applies-to ID" := GenJournalLine."Applies-to ID";
        CustLedgerEntry.Modify;
        CreateDetailedCustomerLedgerEntry(CustLedgerEntry."Entry No.", GenJournalLine."Account No.");

        // Exercise.
        REPORT.Run(REPORT::"Deposit Test Report");

        // Verify: Verify the Document Type, Account Type, Dimension and Applies To ID after running Deposit Test Report.
        LibraryReportDataSet.LoadDataSetFile;
        LibraryReportDataSet.AssertElementWithValueExists(DimensionCap, 0);  // Blank Dimension.
        LibraryReportDataSet.AssertElementWithValueExists(GenJournalLineAccountTypeCap, Format(GenJournalLine."Account Type"::Customer));
        LibraryReportDataSet.AssertElementWithValueExists(GenJournalLineDocumentTypeCap, Format(GenJournalLine."Document Type"::Payment));
        LibraryReportDataSet.AssertElementWithValueExists(GenJournalLineAppliesToIDCap, GenJournalLine."Applies-to ID");
    end;

    [Test]
    [HandlerFunctions('DepositTestReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordApplyVendLedgerDepositTestReport()
    var
        DepositHeader: Record "Deposit Header";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Purpose of the test is to validate Vendor Ledger Entry - OnAfterGetRecord of the Report ID: 10402, Deposit Test Report with Applies To ID.
        // Setup.
        Initialize;
        CreateDepositHeader(DepositHeader);
        CreateGenJournalLine(GenJournalLine, DepositHeader, GenJournalLine."Account Type"::Vendor, CreateVendor);
        LibraryVariableStorage.Enqueue(DepositHeader."No.");  // Enqueue value for use in DepositTestReportRequestPageHandler.
        CreateVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document No.", GenJournalLine."Account No.");
        VendorLedgerEntry."Applies-to ID" := GenJournalLine."Applies-to ID";
        VendorLedgerEntry.Modify;
        CreateDetailedVendorLedgerEntry(VendorLedgerEntry."Entry No.", GenJournalLine."Account No.");

        // Exercise.
        REPORT.Run(REPORT::"Deposit Test Report");

        // Verify: Verify the Document Type, Account Type, Dimension and Applies To ID after running Deposit Test Report.
        LibraryReportDataSet.LoadDataSetFile;
        LibraryReportDataSet.AssertElementWithValueExists(DimensionCap, 0);  // Blank Dimension.
        LibraryReportDataSet.AssertElementWithValueExists(GenJournalLineAccountTypeCap, Format(GenJournalLine."Account Type"::Vendor));
        LibraryReportDataSet.AssertElementWithValueExists(GenJournalLineDocumentTypeCap, Format(GenJournalLine."Document Type"::Payment));
        LibraryReportDataSet.AssertElementWithValueExists(GenJournalLineAppliesToIDCap, GenJournalLine."Applies-to ID");
    end;

    [Test]
    [HandlerFunctions('DepositTestReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDimLoopTypeBankDepositTestReport()
    var
        DepositHeader: Record "Deposit Header";
        GenJournalLine: Record "Gen. Journal Line";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // Purpose of the test is to validate DimensionLoop1 - OnAfterGetRecord of the Report ID: 10402, Deposit Test Report with Account Type Bank Account.
        // Setup.
        Initialize;
        CreateDepositHeader(DepositHeader);
        CreateGenJournalLine(GenJournalLine, DepositHeader, GenJournalLine."Account Type"::"Bank Account", CreateBankAccount);
        CreateDimension(DimensionSetEntry);
        UpdateDimensionOnDepositHeader(DepositHeader, DimensionSetEntry."Dimension Set ID");
        LibraryVariableStorage.Enqueue(DepositHeader."No.");  // Enqueue value for use in DepositTestReportRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Deposit Test Report");

        // Verify: Verify the Document Type, Account Type, Dimension Code and Applies To ID after running Deposit Test Report.
        LibraryReportDataSet.LoadDataSetFile;
        LibraryReportDataSet.AssertElementWithValueExists(DimensionCap, 1);
        LibraryReportDataSet.AssertElementWithValueExists(DimSetEntryDimensionCodeCap, DimensionSetEntry."Dimension Code");
        LibraryReportDataSet.AssertElementWithValueExists(GenJournalLineAccountTypeCap, Format(GenJournalLine."Account Type"::"Bank Account"));
        LibraryReportDataSet.AssertElementWithValueExists(GenJournalLineDocumentTypeCap, Format(GenJournalLine."Document Type"::Payment));
    end;

    [Test]
    [HandlerFunctions('DepositTestReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordDimLoopTypeGLDepositTestReport()
    var
        DepositHeader: Record "Deposit Header";
        GenJournalLine: Record "Gen. Journal Line";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // Purpose of the test is to validate DimensionLoop1 - OnAfterGetRecord of the Report ID: 10402, Deposit Test Report with Account Type GL Account.
        // Setup.
        Initialize;
        CreateDepositHeader(DepositHeader);
        CreateGenJournalLine(GenJournalLine, DepositHeader, GenJournalLine."Account Type"::"G/L Account", CreateGLAccount);
        CreateDimension(DimensionSetEntry);
        UpdateDimensionOnDepositHeader(DepositHeader, DimensionSetEntry."Dimension Set ID");
        LibraryVariableStorage.Enqueue(DepositHeader."No.");  // Enqueue value for use in DepositTestReportRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Deposit Test Report");

        // Verify: Verify the Document Type, Account Type, Dimension Code and Applies To ID after running Deposit Test Report.
        LibraryReportDataSet.LoadDataSetFile;
        LibraryReportDataSet.AssertElementWithValueExists(DimensionCap, 1);
        LibraryReportDataSet.AssertElementWithValueExists(DimSetEntryDimensionCodeCap, DimensionSetEntry."Dimension Code");
        LibraryReportDataSet.AssertElementWithValueExists(GenJournalLineAccountTypeCap, Format(GenJournalLine."Account Type"::"G/L Account"));
        LibraryReportDataSet.AssertElementWithValueExists(GenJournalLineDocumentTypeCap, Format(GenJournalLine."Document Type"::Payment));
    end;

    [Test]
    [HandlerFunctions('DepositTestReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DepositTestReportForEmployee()
    var
        Employee: Record Employee;
        DepositHeader: Record "Deposit Header";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 256390] Print "Deposit Test Report" with Account Type is Employee and descrition the same as employee's Name
        Initialize;

        // [GIVEN] Deposit with line where Account Type is Employee "E" which has Name "N" and description "N"
        CreateDepositHeader(DepositHeader);
        CreateEmployee(Employee);
        CreateGenJournalLine(GenJournalLine, DepositHeader, GenJournalLine."Account Type"::Employee, Employee."No.");
        GenJournalLine.Validate(Description, CopyStr(Employee.FullName, 1, MaxStrLen(GenJournalLine.Description)));
        GenJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(DepositHeader."No.");  // Enqueue value for use in DepositTestReportRequestPageHandler.

        // [WHEN] Run "Deposit Test Report"
        REPORT.Run(REPORT::"Deposit Test Report");

        // [THEN] Employee "E" presents in the report with Name "N"
        // [THEN] Description "N" is not exported
        LibraryReportDataSet.LoadDataSetFile;
        VerifyDepositTestReportEmployee(GenJournalLine, Employee."No." + ' - ' + Employee.FullName);
        LibraryReportDataSet.AssertElementWithValueNotExist('Gen__Journal_Line_Description', Employee.FullName);
        LibraryReportDataSet.AssertElementWithValueNotExist('Gen__Journal_Line_Description', GenJournalLine.Description);
    end;

    [Test]
    [HandlerFunctions('DepositTestReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DepositTestReportForEmployeeWithLineDescription()
    var
        Employee: Record Employee;
        DepositHeader: Record "Deposit Header";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 256390] Print "Deposit Test Report" with Account Type is Employee and descrition different from employee's Name
        Initialize;

        // [GIVEN] Deposit with line where Account Type is Employee "E" which has Name "N" and description "D"
        CreateDepositHeader(DepositHeader);
        CreateEmployee(Employee);
        CreateGenJournalLine(GenJournalLine, DepositHeader, GenJournalLine."Account Type"::Employee, Employee."No.");
        GenJournalLine.Validate(Description, LibraryUTUtility.GetNewCode);
        GenJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(DepositHeader."No.");  // Enqueue value for use in DepositTestReportRequestPageHandler.

        // [WHEN] Run "Deposit Test Report"
        REPORT.Run(REPORT::"Deposit Test Report");

        // [THEN] Employee "E" presents in the report with Name "N"
        // [THEN] Description "N" is not exported
        // [THEN] Description "D" is exported
        LibraryReportDataSet.LoadDataSetFile;
        VerifyDepositTestReportEmployee(GenJournalLine, Employee."No." + ' - ' + Employee.FullName);
        LibraryReportDataSet.AssertElementWithValueNotExist('Gen__Journal_Line_Description', Employee.FullName);
        LibraryReportDataSet.AssertElementWithValueExists('Gen__Journal_Line_Description', GenJournalLine.Description);
    end;

    [Test]
    [HandlerFunctions('DepositTestReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DepositTestReportForRemovedEmployee()
    var
        Employee: Record Employee;
        DepositHeader: Record "Deposit Header";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 256390] Print "Deposit Test Report" with Account Type is Employee and Employee is removed
        Initialize;

        // [GIVEN] Deposit with line where Account Type is Employee "E" which has Name "N"
        CreateDepositHeader(DepositHeader);
        CreateEmployee(Employee);
        CreateGenJournalLine(GenJournalLine, DepositHeader, GenJournalLine."Account Type"::Employee, Employee."No.");
        LibraryVariableStorage.Enqueue(DepositHeader."No.");  // Enqueue value for use in DepositTestReportRequestPageHandler.
        Employee.Delete;

        // [WHEN] Run "Deposit Test Report"
        REPORT.Run(REPORT::"Deposit Test Report");

        // [THEN] Employee "E" presents in the report with Name marked as 'Invalid Employee'
        LibraryReportDataSet.LoadDataSetFile;
        VerifyDepositTestReportEmployee(GenJournalLine, Employee."No." + ' - ' + '<Invalid Employee>');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
    end;

    local procedure CreateDepositHeader(var DepositHeader: Record "Deposit Header")
    begin
        DepositHeader."No." := LibraryUTUtility.GetNewCode;
        DepositHeader."Posting Date" := WorkDate;
        DepositHeader."Document Date" := WorkDate;
        DepositHeader."Bank Account No." := CreateBankAccount;
        DepositHeader."Total Deposit Amount" := LibraryRandom.RandDec(10, 2);
        DepositHeader.Insert;
    end;

    local procedure CreatePostedDeposit(var PostedDepositLine: Record "Posted Deposit Line"; AccountType: Option; AccountNo: Code[20])
    var
        PostedDepositHeader: Record "Posted Deposit Header";
    begin
        PostedDepositHeader."No." := LibraryUTUtility.GetNewCode;
        PostedDepositHeader.Insert;

        PostedDepositLine."Deposit No." := PostedDepositHeader."No.";
        PostedDepositLine."Line No." := LibraryRandom.RandInt(10);
        PostedDepositLine."Account Type" := AccountType;
        PostedDepositLine."Document Type" := PostedDepositLine."Document Type"::Payment;
        PostedDepositLine."Account No." := AccountNo;
        PostedDepositLine.Amount := LibraryRandom.RandDec(10, 2);
        PostedDepositLine.Insert;
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DepositHeader: Record "Deposit Header"; AccountType: Option; AccountNo: Code[20])
    begin
        GenJournalLine."Line No." := LibraryUtility.GetNewRecNo(GenJournalLine, GenJournalLine.FieldNo("Line No."));
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
        GenJournalLine."Account Type" := AccountType;
        GenJournalLine."Account No." := AccountNo;
        GenJournalLine.Amount := -DepositHeader."Total Deposit Amount";
        GenJournalLine."Document No." := LibraryUTUtility.GetNewCode;
        GenJournalLine."Applies-to ID" := LibraryUTUtility.GetNewCode;
        GenJournalLine."Document Date" := WorkDate;
        GenJournalLine.Insert;
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode;
        GLAccount.Insert;
        exit(GLAccount."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode;
        Customer.Insert;
        exit(Customer."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode;
        Vendor.Insert;
        exit(Vendor."No.");
    end;

    local procedure CreateICPartner(): Code[20]
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Code := LibraryUTUtility.GetNewCode;
        ICPartner.Insert;
        exit(ICPartner.Code);
    end;

    local procedure CreateEmployee(var Employee: Record Employee): Code[20]
    begin
        Employee."No." := LibraryUTUtility.GetNewCode;
        Employee."First Name" := LibraryUTUtility.GetNewCode;
        Employee.Insert;
        exit(Employee."No.");
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode;
        BankAccount.Insert;
        exit(BankAccount."No.");
    end;

    local procedure CreateDimension(var DimensionSetEntry: Record "Dimension Set Entry")
    var
        DimensionValue: Record "Dimension Value";
        Dimension: Record Dimension;
    begin
        Dimension.Code := LibraryUTUtility.GetNewCode;
        Dimension.Insert;
        DimensionValue.Code := LibraryUTUtility.GetNewCode;
        DimensionValue."Dimension Code" := Dimension.Code;
        DimensionValue.Insert;
        CreateDimensionSetEntry(DimensionSetEntry, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateDimensionSetEntry(var DimensionSetEntry: Record "Dimension Set Entry"; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        DimensionSetEntry2: Record "Dimension Set Entry";
    begin
        DimensionSetEntry2.FindLast;
        DimensionSetEntry."Dimension Set ID" := DimensionSetEntry2."Dimension Set ID" + 1;
        DimensionSetEntry."Dimension Code" := DimensionCode;
        DimensionSetEntry."Dimension Value Code" := DimensionValueCode;
        DimensionSetEntry.Insert;
    end;

    local procedure CreateCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentNo: Code[20]; CustomerNo: Code[20])
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry2.FindLast;
        CustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No." + 1;
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Document No." := DocumentNo;
        CustLedgerEntry.Open := true;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry.Insert;
    end;

    local procedure CreateDetailedCustomerLedgerEntry(CustLedgerEntryNo: Integer; CustomerNo: Code[20])
    var
        DetailedCustomerLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedCustomerLedgEntry2: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustomerLedgEntry2.FindLast;
        DetailedCustomerLedgEntry."Entry No." := DetailedCustomerLedgEntry2."Entry No." + 1;
        DetailedCustomerLedgEntry."Cust. Ledger Entry No." := CustLedgerEntryNo;
        DetailedCustomerLedgEntry."Customer No." := CustomerNo;
        DetailedCustomerLedgEntry.Amount := LibraryRandom.RandDec(10, 2);
        DetailedCustomerLedgEntry.Insert(true);
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentNo: Code[20]; VendorNo: Code[20])
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry2.FindLast;
        VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Document No." := DocumentNo;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert;
    end;

    local procedure CreateDetailedVendorLedgerEntry(VendorLedgerEntryNo: Integer; VendorNo: Code[20])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry2.FindLast;
        DetailedVendorLedgEntry."Entry No." := DetailedVendorLedgEntry2."Entry No." + 1;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntryNo;
        DetailedVendorLedgEntry."Vendor No." := VendorNo;
        DetailedVendorLedgEntry.Amount := LibraryRandom.RandDec(10, 2);
        DetailedVendorLedgEntry.Insert(true);
    end;

    local procedure UpdateEntryNoPostedDepositLine(PostedDepositLine: Record "Posted Deposit Line"; EntryNo: Integer)
    begin
        PostedDepositLine."Entry No." := EntryNo;
        PostedDepositLine.Modify;
    end;

    local procedure UpdateApplyToDocGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::Invoice;
        GenJournalLine."Applies-to Doc. No." := LibraryUTUtility.GetNewCode;
        GenJournalLine.Modify;
    end;

    local procedure UpdateApplyToDocVendorLedgerEntry(VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        VendorLedgerEntry."Applies-to ID" := GenJournalLine."Applies-to ID";
        VendorLedgerEntry."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type";
        VendorLedgerEntry."Applies-to Doc. No." := GenJournalLine."Applies-to Doc. No.";
        VendorLedgerEntry.Modify;
    end;

    local procedure UpdateApplyToDocCustomerLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        CustLedgerEntry."Applies-to ID" := GenJournalLine."Applies-to ID";
        CustLedgerEntry."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type";
        CustLedgerEntry."Applies-to Doc. No." := GenJournalLine."Applies-to Doc. No.";
        CustLedgerEntry.Modify;
    end;

    local procedure UpdateDimensionOnDepositHeader(DepositHeader: Record "Deposit Header"; DimensionSetID: Integer)
    begin
        DepositHeader."Dimension Set ID" := DimensionSetID;
        DepositHeader.Modify;
    end;

    local procedure VerifyDepositTestReportEmployee(GenJournalLine: Record "Gen. Journal Line"; AccountName: Text)
    begin
        LibraryReportDataSet.AssertElementWithValueExists(GenJournalLineAccountTypeCap, Format(GenJournalLine."Account Type"::Employee));
        LibraryReportDataSet.AssertElementWithValueExists(GenJournalLineDocumentTypeCap, Format(GenJournalLine."Document Type"::Payment));
        LibraryReportDataSet.AssertElementWithValueExists(AmountCap, -GenJournalLine.Amount);
        LibraryReportDataSet.AssertElementWithValueExists('Gen__Journal_Line_Account_No_', GenJournalLine."Account No.");
        LibraryReportDataSet.AssertElementWithValueExists('Account_No_____________AccountName', AccountName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DepositRequestPageHandler(var Deposit: TestRequestPage Deposit)
    var
        No: Variant;
        ShowApplications: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(ShowApplications);
        Deposit."Posted Deposit Header".SetFilter("No.", No);
        Deposit.ShowApplications.SetValue(ShowApplications);
        Deposit.SaveAsXml(LibraryReportDataSet.GetParametersFileName, LibraryReportDataSet.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DepositTestReportRequestPageHandler(var DepositTestReport: TestRequestPage "Deposit Test Report")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        DepositTestReport."Deposit Header".SetFilter("No.", No);
        DepositTestReport.ShowApplications.SetValue(true);
        DepositTestReport.ShowDimensions.SetValue(true);
        DepositTestReport.SaveAsXml(LibraryReportDataSet.GetParametersFileName, LibraryReportDataSet.GetFileName);
    end;
}

