codeunit 142067 "UT REPORTS GENERAL"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        CountryFilterTxt: Label '%1: %2';
        LastUsedTxt: Label 'Last used options and filters';
        Assert: Codeunit Assert;

    [Test]
    [HandlerFunctions('CurrencyListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCurrencyList()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Purpose of the test is to validate Currency - OnAfterGetRecord trigger of Report ID - 10308.
        // Setup: Create Currency and Currency Exchange Rate.
        Initialize;
        CreateCurrencyAndExchangeRate(CurrencyExchangeRate);

        // Exercise.
        REPORT.Run(REPORT::"Currency List");  // Opens CurrencyListRequestPageHandler.

        // Verify: Verify Currency Code after report generation.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('Currency_Code', CurrencyExchangeRate."Currency Code");
        LibraryReportDataset.AssertElementWithValueExists(
          'CurrExchRate__Exchange_Rate_Amount_', CurrencyExchangeRate."Exchange Rate Amount");
    end;

    [Test]
    [HandlerFunctions('LanguageListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordLanguageList()
    var
        LanguageCode: Code[10];
    begin
        // Purpose of the test is to validate Language - OnAfterGetRecord trigger of Report ID - 10310.
        // Setup: Create Language.
        Initialize;
        LanguageCode := CreateLanguage;

        // Exercise.
        REPORT.Run(REPORT::"Language List");  // Opens LanguageListRequestPageHandler.

        // Verify: Verify Windows Language Name of Language after report generation.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('Language_Code', LanguageCode);
    end;

    [Test]
    [HandlerFunctions('ReasonCodeListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportReasonCodeList()
    var
        ReasonCode: Record "Reason Code";
        "Code": Code[10];
    begin
        // Purpose of the test is to validate Reason Code - OnPreReport trigger of Report ID - 10312.
        // Setup: Create Reason Code.
        Initialize;
        Code := CreateReasonCode;

        // Exercise.
        REPORT.Run(REPORT::"Reason Code List");  // Opens ReasonCodeListRequestPageHandler.

        // Verify: Verify Filters on Reason Code is updated on Report Reason Code List.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(
          'ReasonFilter', StrSubstNo('%1: %2', ReasonCode.FieldCaption(Code), Code));
    end;

    [Test]
    [HandlerFunctions('CountryRegionListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportCountryRegionList()
    var
        CountryRegion: Record "Country/Region";
    begin
        // Purpose of the test is to validate OnPreReport trigger of Report ID - 10307 Country/Region List.
        // Setup.
        Initialize;
        CreateCountryRegion(CountryRegion);

        // Exercise.
        REPORT.Run(REPORT::"Country/Region List");  // Opens handler - CountryRegionListRequestPageHandler.

        // Verify: Verify Country Region Code and Name on Report - Country/Region List.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('CountryFilter', StrSubstNo(CountryFilterTxt, CountryRegion.FieldCaption(Code), CountryRegion.Code));
        LibraryReportDataset.AssertElementWithValueExists('Country_Region_Code', CountryRegion.Code);
        LibraryReportDataset.AssertElementWithValueExists('Country_Region_Name', CountryRegion.Name);
    end;

    [Test]
    [HandlerFunctions('GLRegisterRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLRegisterSavedSettings()
    var
        ObjectOptions: Record "Object Options";
    begin
        // [FEATURE] [G/L Register] [UT]
        // [SCENARIO 331052] Settings of the "G/L Register" report are saved after its run.
        Initialize;
        Assert.IsFalse(
          ObjectOptions.Get(LastUsedTxt, REPORT::"G/L Register", ObjectOptions."Object Type"::Report, UserId, CompanyName), '');

        // [WHEN] Run "G/L Register" report.
        REPORT.Run(REPORT::"G/L Register");

        // [THEN] Object options with report parameters were not created for "G/L Register" report.
        Assert.IsFalse(
          ObjectOptions.Get(LastUsedTxt, REPORT::"G/L Register", ObjectOptions."Object Type"::Report, UserId, CompanyName), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardStatementAddedToReportSelectionsOnCompanyInit()
    var
        ReportSelections: Record "Report Selections";
        ReportSelectionMgt: Codeunit "Report Selection Mgt.";
    begin
        // [FEATURE] [Report Selection] [UT]
        // [SCENARIO 314076] A line with Report ID 1316 "Standard Statement" is added to Report Selections for Usage "Customer Statement" when "Company-Initialize" runs.
        Initialize;
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"C.Statement");
        ReportSelections.DeleteAll();

        // [WHEN] Run InitReportUsage function of "Report Selection Mgt." codeunit for Usage "C.Statement".
        ReportSelectionMgt.InitReportSelection(ReportSelections.Usage::"C.Statement");

        // [THEN] A line with Report ID 1316 was added to Report Selections for Usage "Customer Statement".
        ReportSelections.SetRange("Report ID", REPORT::"Standard Statement");
        Assert.RecordIsNotEmpty(ReportSelections);
    end;

    [Test]
    [HandlerFunctions('CustomerStatementsCancelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RunCustomerStatementsReportSelections()
    var
        ReportSelections: Record "Report Selections";
        ReportSelectionMgt: Codeunit "Report Selection Mgt.";
    begin
        // [FEATURE] [Report Selection] [UT]
        // [SCENARIO 314076] Run report 153 "Customer Statement" in case Report Selections for "C.Statement" contains the only line with Report 10072 "Customer Statements".
        Initialize;
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"C.Statement");
        ReportSelections.DeleteAll();

        // [GIVEN] A line with the report 10072 "Customer Statements" in the Report Selection for Usage "Customer Statement".
        InsertReportSelections(ReportSelections.Usage::"C.Statement", '1', REPORT::"Customer Statements");

        // [WHEN] Run report 153 "Customer Statement".
        REPORT.Run(REPORT::"Customer Statement");

        // [THEN] Report 10072 "Customer Statements" is run.
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
    end;

    local procedure CreateCountryRegion(var CountryRegion: Record "Country/Region")
    begin
        CountryRegion.Code := LibraryUTUtility.GetNewCode10;
        CountryRegion.Name := LibraryUTUtility.GetNewCode;
        CountryRegion.Insert();
        LibraryVariableStorage.Enqueue(CountryRegion.Code);  // Enqueue required inside CountryRegionListRequestPageHandler.
    end;

    local procedure CreateCurrencyAndExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        Currency: Record Currency;
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10;
        Currency.Insert();
        CurrencyExchangeRate."Currency Code" := Currency.Code;
        CurrencyExchangeRate."Exchange Rate Amount" := LibraryRandom.RandDec(10, 2);
        CurrencyExchangeRate.Insert();

        // Enqueue required inside CurrencyListRequestPageHandler.
        LibraryVariableStorage.Enqueue(Currency.Code);
    end;

    local procedure CreateLanguage(): Code[10]
    var
        Language: Record Language;
    begin
        Language.Code := LibraryUTUtility.GetNewCode10;
        Language.Insert();

        // Enqueue required for LanguageListRequestPageHandler.
        LibraryVariableStorage.Enqueue(Language.Code);
        exit(Language.Code);
    end;

    local procedure CreateReasonCode(): Code[10]
    var
        ReasonCode: Record "Reason Code";
    begin
        ReasonCode.Code := LibraryUTUtility.GetNewCode10;
        ReasonCode.Insert();

        // Enqueue required for ReasonCodeListRequestPageHandler.
        LibraryVariableStorage.Enqueue(ReasonCode.Code);
        exit(ReasonCode.Code);
    end;

    local procedure InsertReportSelections(ReportUsage: Option; Sequence: Code[10]; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Init();
        ReportSelections.Usage := ReportUsage;
        ReportSelections.Sequence := Sequence;
        ReportSelections."Report ID" := ReportID;
        ReportSelections.Insert();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CurrencyListRequestPageHandler(var CurrencyList: TestRequestPage "Currency List")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        CurrencyList.Currency.SetFilter(Code, Code);
        CurrencyList.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LanguageListRequestPageHandler(var LanguageList: TestRequestPage "Language List")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        LanguageList.Language.SetFilter(Code, Code);
        LanguageList.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReasonCodeListRequestPageHandler(var ReasonCodeList: TestRequestPage "Reason Code List")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        ReasonCodeList."Reason Code".SetFilter(Code, Code);
        ReasonCodeList.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CountryRegionListRequestPageHandler(var CountryRegionList: TestRequestPage "Country/Region List")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        CountryRegionList."Country/Region".SetFilter(Code, Code);
        CountryRegionList.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLRegisterRequestPageHandler(var GLRegister: TestRequestPage "G/L Register")
    begin
        GLRegister.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerStatementsCancelRequestPageHandler(var CustomerStatements: TestRequestPage "Customer Statements")
    begin
        CustomerStatements.Cancel.Invoke;
    end;
}

