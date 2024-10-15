codeunit 144062 "UT REP Intrastat"
{
    // Test for feature Intrastat.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        GLAccountNoCap: Label 'G_L_Account_No_';
        IntrastatJnlLineVATRegistrationNoCap: Label 'Intrastat_Jnl__Line__VAT_Registration_No__';
        IntraformBufferTotalWeightCap: Label 'Intra___form_Buffer__Total_Weight_';
        IntraFormBufferCorrectiveEntryCap: Label 'Intra___form_Buffer_Corrective_entry';
        IntrastatJnlLinePaymentMethodCap: Label 'Intrastat_Jnl__Line__Payment_Method_';
        IntrastatPaymentMethodTxt: Label 'A', Comment = 'Single character string is required for the field Intrastat Payment Method which is of 1 character';
        IntraFormBufferCountryOfOriginCodeCap: Label 'Intra___form_Buffer__Country_of_Origin_Code_';
        StartOnHandAmountCap: Label 'StartOnHand___Amount_Control1130105';
        TotalAmountCap: Label 'TotalAmount';
        TotRoundAmountCap: Label 'TotRoundAmount';

    [Test]
    [HandlerFunctions('IntrastatMonthlyReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordIntrastatJnlLineIntrastatMonthlyReport()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // Purpose of the test is to verify VAT Registration No. and Total Weight on Intrastat - Monthly Report.

        // Setup: Create Intrastat Journal Line.
        Initialize;
        CreateIntrastatJournalLine(IntrastatJnlLine, false);  // FALSE for EU Service.

        // Exercise.
        RunIntrastatMonthlyReport(IntrastatJnlLine."Journal Batch Name");

        // Verify: Verify VAT Registration No. and Total Weight on Intrastat - Monthly Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(IntrastatJnlLineVATRegistrationNoCap, IntrastatJnlLine."Partner VAT ID");
        LibraryReportDataset.AssertElementWithValueExists(IntraformBufferTotalWeightCap, IntrastatJnlLine."Total Weight");
        LibraryReportDataset.AssertElementWithValueExists(
          IntraFormBufferCountryOfOriginCodeCap, IntrastatJnlLine."Country/Region of Origin Code");
        LibraryReportDataset.AssertElementWithValueExists(TotRoundAmountCap, Round(IntrastatJnlLine.Amount, 1));  // Using 1 for rounding Amount to whole value.
    end;

    [Test]
    [HandlerFunctions('IntrastatQuarterlyReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordIntrastatJnlLineIntrastatQuarterlyReport()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // Purpose of the test is to verify VAT Registration No. and Corrective Entry on Intrastat - Quarterly Report.

        // Setup: Create Intrastat Journal Line.
        Initialize;
        CreateIntrastatJournalLine(IntrastatJnlLine, false);  // FALSE for EU Service.

        // Exercise.
        RunIntrastatQuarterlyReport(IntrastatJnlLine."Journal Batch Name");

        // Verify: Verify VAT Registration No. and Corrective Entry on Intrastat - Quarterly Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(IntrastatJnlLineVATRegistrationNoCap, IntrastatJnlLine."Partner VAT ID");
        LibraryReportDataset.AssertElementWithValueExists(IntraFormBufferCorrectiveEntryCap, true);
    end;

    [Test]
    [HandlerFunctions('IntrastatMonthlyReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPaymentMethodIntrastatMonthlyReport()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PaymentMethod: Record "Payment Method";
    begin
        // Purpose of the test is to verify VAT Registration No. and Intrastat Payment Method on Intrastat - Monthly Report.

        // Setup: Create Intrastat Journal Line.
        Initialize;
        CreateIntrastatJournalLine(IntrastatJnlLine, true);  // TRUE for EU Service.
        PaymentMethod.Get(IntrastatJnlLine."Payment Method");

        // Exercise.
        RunIntrastatMonthlyReport(IntrastatJnlLine."Journal Batch Name");

        // Verify: Verify VAT Registration No. and Intrastat Payment Method on Intrastat - Monthly Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(IntrastatJnlLineVATRegistrationNoCap, IntrastatJnlLine."Partner VAT ID");
        LibraryReportDataset.AssertElementWithValueExists(IntrastatJnlLinePaymentMethodCap, PaymentMethod."Intrastat Payment Method");
    end;

    [Test]
    [HandlerFunctions('IntrastatQuarterlyReportRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPaymentMethodIntrastatQuarterlyReport()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        PaymentMethod: Record "Payment Method";
    begin
        // Purpose of the test is to verify VAT Registration No. and Intrastat Payment Method on Intrastat - Quarterly Report.

        // Setup: Create Intrastat Journal Line.
        Initialize;
        CreateIntrastatJournalLine(IntrastatJnlLine, true);  // TRUE for EU Service.
        PaymentMethod.Get(IntrastatJnlLine."Payment Method");

        // Exercise.
        RunIntrastatQuarterlyReport(IntrastatJnlLine."Journal Batch Name");

        // Verify: Verify VAT Registration No. and Intrastat Payment Method on Intrastat - Quarterly Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(IntrastatJnlLineVATRegistrationNoCap, IntrastatJnlLine."Partner VAT ID");
        LibraryReportDataset.AssertElementWithValueExists(IntrastatJnlLinePaymentMethodCap, PaymentMethod."Intrastat Payment Method");
    end;

    [Test]
    [HandlerFunctions('AccountBookSheetPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GLBookEntryOnAfterGetRecordAccountBookSheetPrint()
    var
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
        Amount: Decimal;
    begin
        // Purpose of the test is to validate GL Book Entry - OnAfterGetRecord Trigger of Report - 121069 Account Book Sheet - Print.

        // Setup: Create two G/L Entry and GL Book Entry with same G/L Account and Transaction Number.
        Initialize;
        CreateGLEntry(GLEntry, CreateGLAccount, LibraryRandom.RandInt(10), LibraryRandom.RandDec(10, 2));  // Random Integer - Transaction Number and Random Decimal - Amount.
        CreateGLBookEntry(GLEntry."G/L Account No.", GLEntry."Transaction No.");
        CreateGLEntry(GLEntry2, GLEntry."G/L Account No.", GLEntry."Transaction No.", -LibraryRandom.RandDecInRange(10, 100, 2));  // Random Decimal Range - Amount.
        CreateGLBookEntry(GLEntry."G/L Account No.", GLEntry."Transaction No.");
        Amount := GLEntry.Amount + GLEntry2.Amount;
        LibraryVariableStorage.Enqueue(GLEntry."G/L Account No.");

        // Exercise.
        REPORT.Run(REPORT::"Account Book Sheet - Print");  // Opens handler - AccountBookSheetPrintRequestPageHandler.

        // Verify: Verify G/L Account No, Amount on generated XML of Report - Account Book Sheet - Print.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(GLAccountNoCap, GLEntry."G/L Account No.");
        LibraryReportDataset.AssertElementWithValueExists(TotalAmountCap, Amount);
        LibraryReportDataset.AssertElementWithValueExists(StartOnHandAmountCap, Amount);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
    end;

    local procedure CreateCountryRegionCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Code := LibraryUTUtility.GetNewCode10;
        CountryRegion.Insert;
        exit(CountryRegion.Code);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode;
        GLAccount.Insert;
        exit(GLAccount."No.");
    end;

    local procedure CreateGLBookEntry(GLAccountNo: Code[20]; TransactionNo: Integer)
    var
        GLBookEntry: Record "GL Book Entry";
        GLBookEntry2: Record "GL Book Entry";
    begin
        GLBookEntry2.FindLast;
        GLBookEntry."Entry No." := GLBookEntry2."Entry No." + 1;
        GLBookEntry."G/L Account No." := GLAccountNo;
        GLBookEntry."Posting Date" := WorkDate;
        GLBookEntry."Transaction No." := TransactionNo;
        GLBookEntry.Insert;
    end;

    local procedure CreateGLEntry(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20]; TransactionNo: Integer; Amount: Decimal)
    var
        GLEntry2: Record "G/L Entry";
    begin
        GLEntry2.FindLast;
        GLEntry."Entry No." := GLEntry2."Entry No." + 1;
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry."Posting Date" := WorkDate;
        GLEntry.Amount := Amount;
        GLEntry."Transaction No." := TransactionNo;
        GLEntry.Insert;
    end;

    local procedure CreateIntrastatJournalLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; EUService: Boolean)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch, EUService);
        IntrastatJnlLine."Journal Template Name" := IntrastatJnlBatch."Journal Template Name";
        IntrastatJnlLine."Journal Batch Name" := IntrastatJnlBatch.Name;
        IntrastatJnlLine."Partner VAT ID" := LibraryUTUtility.GetNewCode;
        IntrastatJnlLine."Tariff No." := LibraryUTUtility.GetNewCode10;  // Taking length for Tariff No. Code 10 because Tariff No. in Intra - form Buffer table is of Code 10.
        IntrastatJnlLine."Country/Region Code" := CreateCountryRegionCode;
        IntrastatJnlLine."Payment Method" := CreatePaymentMethod;
        IntrastatJnlLine."Service Tariff No." := IntrastatJnlLine."Tariff No.";
        IntrastatJnlLine."Country/Region of Origin Code" := IntrastatJnlLine."Country/Region Code";
        IntrastatJnlLine."Transaction Type" := LibraryUTUtility.GetNewCode10;
        IntrastatJnlLine."Net Weight" := LibraryRandom.RandDec(10, 2);
        IntrastatJnlLine."Total Weight" := IntrastatJnlLine."Net Weight";
        IntrastatJnlLine."Corrective entry" := true;
        IntrastatJnlLine.Insert;
    end;

    local procedure CreateIntrastatJournalTemplateAndBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; EUService: Boolean)
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        IntrastatJnlTemplate.Name := LibraryUTUtility.GetNewCode10;
        IntrastatJnlTemplate.Insert;
        IntrastatJnlBatch."Journal Template Name" := IntrastatJnlTemplate.Name;
        IntrastatJnlBatch.Name := IntrastatJnlTemplate.Name;
        IntrastatJnlBatch."EU Service" := EUService;
        IntrastatJnlBatch.Insert;
    end;

    local procedure CreatePaymentMethod(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.Code := LibraryUTUtility.GetNewCode10;
        PaymentMethod."Intrastat Payment Method" := IntrastatPaymentMethodTxt;
        PaymentMethod.Insert;
        exit(PaymentMethod.Code);
    end;

    local procedure RunIntrastatMonthlyReport(JournalBatchName: Code[10])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatMonthlyReport: Report "Intrastat - Monthly Report";
    begin
        Clear(IntrastatMonthlyReport);
        IntrastatJnlLine.SetRange("Journal Batch Name", JournalBatchName);
        IntrastatMonthlyReport.SetTableView(IntrastatJnlLine);
        IntrastatMonthlyReport.Run;  // Opens handler - IntrastatMonthlyReportRequestPageHandler.
    end;

    local procedure RunIntrastatQuarterlyReport(JournalBatchName: Code[10])
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatQuarterlyReport: Report "Intrastat - Quarterly Report";
    begin
        Clear(IntrastatQuarterlyReport);
        IntrastatJnlLine.SetRange("Journal Batch Name", JournalBatchName);
        IntrastatQuarterlyReport.SetTableView(IntrastatJnlLine);
        IntrastatQuarterlyReport.Run;  // Opens handler - IntrastatQuarterlyReportRequestPageHandler.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AccountBookSheetPrintRequestPageHandler(var AccountBookSheetPrint: TestRequestPage "Account Book Sheet - Print")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        AccountBookSheetPrint."G/L Account".SetFilter("No.", No);
        AccountBookSheetPrint."G/L Account".SetFilter("Date Filter", Format(WorkDate));
        AccountBookSheetPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatMonthlyReportRequestPageHandler(var IntrastatMonthlyReport: TestRequestPage "Intrastat - Monthly Report")
    begin
        IntrastatMonthlyReport.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatQuarterlyReportRequestPageHandler(var IntrastatQuarterlyReport: TestRequestPage "Intrastat - Quarterly Report")
    begin
        IntrastatQuarterlyReport.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

