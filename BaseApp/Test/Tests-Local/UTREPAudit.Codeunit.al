codeunit 144004 "UT REP Audit"
{
    // Test for feature Audit.
    // 1-2.  Purpose of the test is to validate OnValidate trigger of Start Date for Tax Authority - Audit File report.
    // 3.    Purpose of the test is to validate OnInitReport trigger for Tax Authority - Audit File report.
    // 4-5.  Purpose of the test is to validate OnPostReport trigger for Tax Authority - Audit File report.
    // 6-14. Purpose of the test is to validate OnPreReport trigger for Tax Authority - Audit File report.
    // 15.   Purpose of the test is to validate OnInitReport trigger for Tax Authority - Audit File report for LCY Code on General Ledger Setup.
    // 
    // Covers Test Cases for WI - 342835
    // -------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                          ID                                               TFS ID
    // -------------------------------------------------------------------------------------------------------------------------------
    // OnValidateStartDateExcludeBeginBalanceChecked                                                             151644
    // OnValidateStartDateExcludeBeginBalanceUnchecked                                                           151645
    // OnInitReportAuditFileCompInfoVATRegNoError                                                                151540
    // OnPostReportAuditFileCustomerVATRegNoError                                                                151541
    // OnPostReportAuditFileVendorVATRegNoError                                                                  151542
    // OnPreReportAuditFileHigherEndDateError                                                                    151649
    // OnPreReportAuditFileBlankEndDateError                                                                     151270
    // OnPreReportAuditFileStartEndDateInFiscalYearError                                                         151272, 151273
    // OnPreReportAuditFileStartDateEarlierThanEndDateError                                                      151648
    // OnPreReportAuditFileBlankStartDateOnError                                                                 151269
    // OnPreReportAuditFileStartDateInAccountPeriodError                                                         151271
    // OnPreReportAuditFileLongFileNameError                                                                     151237
    // OnPreReportAuditFileBlankFileNameError                                                                    151652
    // OnPreReportAuditFileFileNameExtensionError                                                                151651
    // OnInitReportAuditFileBlankLCYCodeError                                                                    151538

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        DialogErr: Label 'Dialog';
        TestFieldErr: Label 'TestField';
        VATRegNoTxt: Label 'NL123456789B5544';
        VATRegNoFormatTxt: Label 'NL#########B####';
        LibraryRandom: Codeunit "Library - Random";
        FileManagement: Codeunit "File Management";

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileReqestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateStartDateExcludeBeginBalanceChecked()
    begin
        // Purpose of the test is to validate OnValidate trigger for report ID 11412 - Tax Authority - Audit File report for Start Date as after begin date of fiscal year.
        ExcludeBeginBalanceOnAuditFileReport(Today, true);
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileReqestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateStartDateExcludeBeginBalanceUnchecked()
    begin
        // Purpose of the test is to validate OnValidate trigger for report ID 11412 - Tax Authority - Audit File report for Start Date as begining date of fiscal year.
        ExcludeBeginBalanceOnAuditFileReport(GetFiscalYearStartDate, false);  // Required Start Date as current year begining date.
    end;

    local procedure ExcludeBeginBalanceOnAuditFileReport(StartDate: Date; ExcludeBeginBalance: Boolean)
    var
        TaxAuthorityAuditFile: Report "Tax Authority - Audit File";
    begin
        // Setup: Set File name, Start Date, End date on Tax Authority - Audit File report.
        EnqueueTaxAuthorityAuditFile(StartDate, Today, ExcludeBeginBalance);

        // Exercise: Run Tax Authority - Audit File report.
        TaxAuthorityAuditFile.SetFileName(FileManagement.ServerTempFileName('xaf'));
        TaxAuthorityAuditFile.Run;

        // Verify: Verify Exclude Begin Balance field on Tax Authority - Audit File report, verification done by TaxAuthorityAuditFileReqestPageHandler.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInitReportAuditFileCompInfoVATRegNoError()
    begin
        // Purpose of the test is to validate OnInitReport trigger for report ID 11412 - Tax Authority - Audit File report.

        // Setup: Update Country/Region Code and VAT Registration No. in Company Information.
        UpdateCompanyInformation;

        // Exercise: Run Tax Authority - Audit File report.
        asserterror REPORT.Run(REPORT::"Tax Authority - Audit File");

        // Verify error code, error is 'Length of VAT Registration No. in Company Information  must not exceed 15 characters.'.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileReqestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPostReportAuditFileCustomerVATRegNoError()
    var
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate OnPostReport trigger in report ID 11412 - Tax Authority - Audit File report with Customer VAT Registration No. more than 15 characters.
        VATRegNoError(CreateCustomer, GLEntry."Source Type"::Customer, 0, LibraryRandom.RandInt(100));  // Using Random for Credit Amount.
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileReqestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPostReportAuditFileVendorVATRegNoError()
    var
        GLEntry: Record "G/L Entry";
    begin
        // Purpose of the test is to validate OnPostReport trigger for report ID 11412 - Tax Authority - Audit File report with Vendor VAT Registration No. more than 15 characters.
        VATRegNoError(CreateVendor, GLEntry."Source Type"::Vendor, LibraryRandom.RandInt(100), 0);  // Using Random for Debit Amount.
    end;

    local procedure VATRegNoError(SourceNo: Code[20]; SourceType: Option; CrAmount: Decimal; DrAmount: Decimal)
    begin
        // Setup: Create GL Entry with Customer/Vendor Vat Registration No more than 15 characters.
        CreateGLEntry(SourceNo, SourceType, CrAmount, DrAmount);
        // STRSUBSTNO(FileNameTxt,COPYSTR(CREATEGUID,4,8)),
        EnqueueTaxAuthorityAuditFile(Today, Today, true);

        // Exercise: Run Tax Authority - Audit File report.
        asserterror REPORT.Run(REPORT::"Tax Authority - Audit File");

        // Verify error code, error for OnPostReport trigger in Tax Authority - Audit File report.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileReqestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportAuditFileHigherEndDateError()
    begin
        // Purpose of the test is to validate OnPreReport trigger for report ID 11412 - Tax Authority - Audit File report with end date earlier than start date.
        OnPreReportAuditFileRepError(Today, CalcDate('<1D>', Today));  // Required End Date after date from current date.
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileReqestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportAuditFileBlankEndDateError()
    begin
        // Purpose of the test is to validate OnPreReport trigger for report ID 11412 - Tax Authority - Audit File report with blank end date.
        OnPreReportAuditFileRepError(Today, 0D);
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileReqestPageHandler,CreateFiscalYearRequestPageHandler,ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportAuditFileStartEndDateInFiscalYearError()
    begin
        // Purpose of the test is to validate OnPreReport trigger for report ID 11412 - Tax Authority - Audit File report with start date out of current fiscal year.
        REPORT.Run(REPORT::"Create Fiscal Year"); // Create previous fiscal year.
        OnPreReportAuditFileRepError(CalcDate('<1D>', GetFiscalYearStartDate), Today);  // Required Start Date as date out of fiscal year.
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileReqestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportAuditFileStartDateEarlierThanEndDateError()
    begin
        // Purpose of the test is to validate OnPreReport trigger for report ID 11412 - Tax Authority - Audit File report with start date earlier than end date.
        OnPreReportAuditFileRepError(CalcDate('<1D>', Today), Today);  // Required Start Date as after date from current date.
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileReqestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportAuditFileBlankStartDateOnError()
    begin
        // Purpose of the test is to validate OnPreReport trigger for report ID 11412 - Tax Authority - Audit File report with blank start date.
        OnPreReportAuditFileRepError(0D, Today);
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileReqestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportAuditFileStartDateInAccountPeriodError()
    begin
        // Purpose of the test is to validate OnPreReport trigger for report ID 11412 - Tax Authority - Audit File report with start date beyond Accounting Period setup.
        OnPreReportAuditFileRepError(CalcDate('<-1D>', GetFiscalYearStartDate), Today);  // Required Start Date as out of year date.
    end;

    local procedure OnPreReportAuditFileRepError(StartDate: Date; EndDate: Date)
    begin
        // Setup: Set File name, Start Date, End date on Tax Authority - Audit File report.
        EnqueueTaxAuthorityAuditFile(StartDate, EndDate, true);

        // Exercise: Run Tax Authority - Audit File report.
        asserterror REPORT.Run(REPORT::"Tax Authority - Audit File");

        // Verify error code, error for OnPreReport trigger in Tax Authority - Audit File report.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInitReportAuditFileBlankLCYCodeError()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Purpose of the test is to validate OnInitReport trigger for report ID 11412 - Tax Authority - Audit File report.

        // Setup: Set blank LCY Code on General Ledger Setup.
        GeneralLedgerSetup.Get;
        GeneralLedgerSetup."LCY Code" := '';
        GeneralLedgerSetup.Modify;
        EnqueueTaxAuthorityAuditFile(Today, Today, true);

        // Exercise: Run Tax Authority - Audit File report.
        asserterror REPORT.Run(REPORT::"Tax Authority - Audit File");

        // Verify error Code, actual error is 'LCY Code must have a value in General Ledger Setup: Primary Key=. It cannot be zero or empty.'
        Assert.ExpectedErrorCode(TestFieldErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AuditFileBufferFieldsHaveProperLength()
    var
        AuditFileBuffer: Record "Audit File Buffer";
        GLEntry: Record "G/L Entry";
        DummyCustVendID: Text[35];
    begin
        // [SCENARIO 344653] The fields of table "Audit File Buffer" have correct length

        Assert.AreEqual(MaxStrLen(AuditFileBuffer."Account ID"), MaxStrLen(GLEntry."G/L Account No."), '');
        Assert.AreEqual(MaxStrLen(AuditFileBuffer."Document ID"), MaxStrLen(GLEntry."Document No."), '');
        Assert.AreEqual(MaxStrLen(DummyCustVendID), MaxStrLen(AuditFileBuffer."Source ID"), '');
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode;
        Customer."Country/Region Code" := CreateVATRegNoFormat;
        Customer."VAT Registration No." := VATRegNoTxt;
        Customer.Insert;
        exit(Customer."No.");
    end;

    local procedure CreateGLEntry(SourceNo: Code[20]; SourceType: Option; CrAmount: Decimal; DrAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry."Entry No." := GetGLEntryNo;
        GLEntry."Document Type" := GLEntry."Document Type"::Invoice;
        GLEntry."Document No." := LibraryUTUtility.GetNewCode;
        GLEntry."Posting Date" := Today;
        GLEntry."Credit Amount" := CrAmount;
        GLEntry."Debit Amount" := DrAmount;
        GLEntry."Source Type" := SourceType;
        GLEntry."Source No." := SourceNo;
        GLEntry.Insert;
    end;

    local procedure CreateVATRegNoFormat(): Code[10]
    var
        CountryRegion: Record "Country/Region";
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        CountryRegion.Code := LibraryUTUtility.GetNewCode10;
        CountryRegion.Insert;

        // Create VAT Registration No Format.
        VATRegistrationNoFormat."Country/Region Code" := CountryRegion.Code;
        VATRegistrationNoFormat."Line No." := LibraryRandom.RandInt(10000);  // Using random for Line No.
        VATRegistrationNoFormat.Format := VATRegNoFormatTxt;
        VATRegistrationNoFormat.Insert;
        exit(CountryRegion.Code);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode;
        Vendor."Country/Region Code" := CreateVATRegNoFormat;
        Vendor."VAT Registration No." := VATRegNoTxt;
        Vendor.Insert;
        exit(Vendor."No.");
    end;

    local procedure EnqueueTaxAuthorityAuditFile(StartDate: Date; EndDate: Date; ExcludeBeginBalance: Boolean)
    begin
        LibraryVariableStorage.Enqueue(StartDate); // Enqueue Start Date for TaxAuthorityAuditFileReqestPageHandler.
        LibraryVariableStorage.Enqueue(EndDate); // Enqueue End Date for TaxAuthorityAuditFileReqestPageHandler.
        LibraryVariableStorage.Enqueue(ExcludeBeginBalance); // Enqueue Exclude Begin Balance for TaxAuthorityAuditFileReqestPageHandler.
    end;

    local procedure GetGLEntryNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.FindLast;
        exit(GLEntry."Entry No." + 1);
    end;

    local procedure GetFiscalYearStartDate(): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.FindFirst;
        exit(AccountingPeriod."Starting Date");
    end;

    local procedure UpdateCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get;
        CompanyInformation."Country/Region Code" := CreateVATRegNoFormat;
        CompanyInformation."VAT Registration No." := VATRegNoTxt;
        CompanyInformation.Modify;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateFiscalYearRequestPageHandler(var CreateFiscalYear: TestRequestPage "Create Fiscal Year")
    begin
        CreateFiscalYear.StartingDate.SetValue(CalcDate('<-1Y>', GetFiscalYearStartDate));  // Required previous year date.
        CreateFiscalYear.NoOfPeriods.SetValue(12);
        CreateFiscalYear.PeriodLength.SetValue('<1M>');
        CreateFiscalYear.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TaxAuthorityAuditFileReqestPageHandler(var TaxAuthorityAuditFile: TestRequestPage "Tax Authority - Audit File")
    var
        AccountingPeriod: Record "Accounting Period";
        StartDate: Variant;
        EndDate: Variant;
        ExcludeBalance: Variant;
    begin
        // Verify value of Exclude Balance Boolean.
        LibraryVariableStorage.Dequeue(StartDate); // Dequeue Start Date.
        LibraryVariableStorage.Dequeue(EndDate); // Dequeue End Date.
        LibraryVariableStorage.Dequeue(ExcludeBalance); // Dequeue Exclude Balance.
        // Exception added when End Date [Today] is equal to Fiscal Year Start Date.
        if AccountingPeriod.Get(StartDate) then
            if AccountingPeriod."New Fiscal Year" then
                ExcludeBalance := false;

        TaxAuthorityAuditFile.StartDate.SetValue(StartDate);  // Start Date.
        TaxAuthorityAuditFile.EndDate.SetValue(EndDate);  // End Date.
        TaxAuthorityAuditFile.ExcludeBalance.AssertEquals(ExcludeBalance);
        TaxAuthorityAuditFile.OK.Invoke;
    end;
}

