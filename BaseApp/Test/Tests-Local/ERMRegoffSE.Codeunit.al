#if not CLEAN23
codeunit 144050 "ERM Regoff SE"
{
    //  1..4 Check that Registered Office field on Company Information exists and can accept any value (so is editable).
    //  5..6 Verify the Registered Office Information on the Sale - Quote report.
    //  7..8 Verify the Registered Office Information on the Sale - Invoice report.
    //  9..10 Verify the Registered Office Information on the Order Confirmation report.
    // 11..12 Verify the Registered Office Information on the Sale - Credit Memo report.
    // 
    // Covers Test Cases for WI - 350464
    // -----------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                              TFS ID
    // -----------------------------------------------------------------------------------------------------------------------
    // RegisteredOfficeInfoOnCompanyInformation,RegisteredOfficeOnCompanyInformation,
    // RegisteredOfficeWithSpecialCharacter,RegisteredOfficeLengthError                                                153967
    // RegisteredOfficeInfoOnSalesQuoteReport,ChangeRegisteredOfficeInfoOnSalesQuoteReport                             156516
    // RegisteredOfficeInfoOnSalesInvoiceReport,ChangeRegisteredOfficeInfoOnSalesInvoiceReport                         156527
    // RegisteredOfficeInfoOnSalesOrderConfirmationReport,ChangeRegisteredOfficeInfoOnSalesOrderConfirmationReport     156530
    // RegisteredOfficeInfoOnSalesCrMemoReport,ChangeRegisteredOfficeInfoOnSalesCrMemoReport                           156651

    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteReason = 'Tests are moved to SE Core';
    ObsoleteState = Pending;
    ObsoleteTag = '23.0';

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        CompanyAddressCap: Label 'CompanyAddr4';
        CompanyBoardDirectorCap: Label 'BoardOfDirectorsLocCaption';
        CompanyBoardDirectorValue: Label 'Board Of Directors Location (registered office)';
        CompanyBoardDirectorValue2: Label 'Board of Directors Location (registered office)';
        NumberValue: Label '1234567890';
        SpecialCharacter: Label '@#$123$#@***';
        StringLengthError: Label 'The length of the string is %1, but it must be less than or equal to 20 characters.';
        isInitialized: Boolean;
        CompanyLegalOfficeLbl: Label 'CompanyLegalOffice_Lbl';
        CompanyAddressFullLbl: Label 'CompanyAddress4';


    [Test]
    [Scope('OnPrem')]
    procedure RegisteredOfficeWithAlphaNumericCharacter()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Verify that Registered Office field on Company Information can accept Alphanumeric value(Max of 20 characters is accepted).
        RegisteredOfficeOnCompanyInformation(
          LibraryUtility.GenerateRandomCode(CompanyInformation.FieldNo("Registered Office"), DATABASE::"Company Information"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisteredOfficeWithSpecialCharacter()
    begin
        // Verify that Registered Office field on Company Information can accept Special Character value(Max of 20 characters is accepted).
        RegisteredOfficeOnCompanyInformation(SpecialCharacter);
    end;

    local procedure RegisteredOfficeOnCompanyInformation(RegisteredOffice: Text[20])
    var
        CompanyInformation: Record "Company Information";
    begin
        // Setup.
        Initialize();
        CompanyInformation.Get();

        // Exercise.
        UpdateCompanyInformation(CompanyInformation, RegisteredOffice);

        // Verify: Verify Registered Office field of Company Information accept Special and Numeric Character.
        CompanyInformation.Get();
        CompanyInformation.TestField("Registered Office", RegisteredOffice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisteredOfficeLengthError()
    var
        CompanyInformation: Record "Company Information";
        RegisteredOffice: Text[50];
        TextCount: Integer;
    begin
        // Verify that Registered Office field on Company Information exists and cannot accept input of length > 20.

        // Setup.
        Initialize();
        CompanyInformation.Get();
        RegisteredOffice := LibraryUTUtility.GetNewCode() + NumberValue;  // Assign Registered Office value more than field length.
        TextCount := StrLen(RegisteredOffice);

        // Exercise.
        asserterror CompanyInformation.Validate("Registered Office", RegisteredOffice);

        // Verify: Verify Maximum field length Error.
        Assert.ExpectedError(StrSubstNo(StringLengthError, TextCount));
    end;

    [Test]
    [HandlerFunctions('SalesQuoteReportHandler')]
    [Obsolete('Test is moved to SECore', '23.0')]
    [Scope('OnPrem')]
    procedure RegisteredOfficeInfoOnSalesQuoteReport()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Run the Sales-Quote report and check that the value in the Registered Office field of the Company Information form is shown in the Board of dir. Loc
        // field of the Sales Quote report.
        RegisteredOfficeInfoOnSalesReports(
          SalesHeader."Document Type"::Quote, REPORT::"Standard Sales - Quote",
          CompanyLegalOfficeLbl, CompanyBoardDirectorValue, CompanyAddressFullLbl);
    end;

    local procedure RegisteredOfficeInfoOnSalesReports(DocumentType: Enum "Sales Document Type"; ReportID: Integer; ComBoardDirectorCap: Text[50]; ComBoardDirectorValue: Text[50]; ComAddressCap: Text[50])
    var
        CompanyInformation: Record "Company Information";
        SalesHeader: Record "Sales Header";
    begin
        // Setup.
        Initialize();
        CompanyInformation.Get();
        CreateSalesDocument(SalesHeader, DocumentType);

        // Exercise.
        RunSalesReport(SalesHeader."Document Type", SalesHeader."No.", ReportID);

        // Verify: Verify Register Office Information on Report.
        VerifyReportValue(
          ComBoardDirectorCap, Format(ComBoardDirectorValue),
          ComAddressCap, Format(CompanyInformation."Post Code" + ' ' + CompanyInformation.City));
    end;

    [Test]
    [HandlerFunctions('SalesQuoteReportHandler')]
    [Obsolete('Test is moved to SECore', '23.0')]
    [Scope('OnPrem')]
    procedure ChangeRegisteredOfficeInfoOnSalesQuoteReport()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Run the Sales-Quote report and check that the change value in the Registered Office field of the Company Information form is shown in the Board of dir. Loc
        // field of the Sales Quote report
        ChangeRegisteredOfficeInfoOnSalesReports(
          SalesHeader."Document Type"::Quote, REPORT::"Standard Sales - Quote", CompanyLegalOfficeLbl, CompanyBoardDirectorValue,
          CompanyAddressFullLbl);
    end;

    local procedure ChangeRegisteredOfficeInfoOnSalesReports(DocumentType: Enum "Sales Document Type"; ReportID: Integer; ComBoardDirectorCap: Text[50]; ComBoardDirectorValue: Text[50]; ComInfoCap: Text[50])
    var
        CompanyInformation: Record "Company Information";
        SalesHeader: Record "Sales Header";
    begin
        // Setup.
        Initialize();
        CompanyInformation.Get();
        CreateSalesDocument(SalesHeader, DocumentType);
        UpdateCompanyInformation(CompanyInformation, LibraryUtility.GenerateGUID());

        // Exercise.
        RunSalesReport(SalesHeader."Document Type", SalesHeader."No.", ReportID);

        // Verify: Verify Register Office Information on Report.
        VerifyReportValue(
          ComBoardDirectorCap, Format(ComBoardDirectorValue),
          ComInfoCap, Format(CompanyInformation."Post Code" + ' ' + CompanyInformation.City));
    end;

    local procedure RegisteredOfficeInfoOnSalesReport(DocumentType: Enum "Sales Document Type"; ReportID: Integer)
    var
        CompanyInformation: Record "Company Information";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // Setup.
        CompanyInformation.Get();
        CreateSalesDocument(SalesHeader, DocumentType);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise.
        RunSalesReport(SalesHeader."Document Type", DocumentNo, ReportID);

        // Verify: Verify Register Office Information on Report.
        VerifyReportValue(
          CompanyBoardDirectorCap, Format(CompanyBoardDirectorValue2),
          CompanyAddressCap, Format(CompanyInformation."Post Code" + ' ' + CompanyInformation.City));
    end;

    local procedure ChangeRegisteredOfficeInfoOnSalesReport(DocumentType: Enum "Sales Document Type"; ReportID: Integer)
    var
        CompanyInformation: Record "Company Information";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // Setup.
        Initialize();
        CompanyInformation.Get();
        CreateSalesDocument(SalesHeader, DocumentType);
        UpdateCompanyInformation(CompanyInformation, LibraryUtility.GenerateGUID());
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise.
        RunSalesReport(SalesHeader."Document Type", DocumentNo, ReportID);

        // Verify: Verify Register Office Information on Report.
        VerifyReportValue(
          CompanyBoardDirectorCap, Format(CompanyBoardDirectorValue2),
          CompanyAddressCap, Format(CompanyInformation."Post Code" + ' ' + CompanyInformation.City));
    end;

#if not CLEAN22
    [Test]
    [Scope('OnPrem')]
    procedure SIEUpdateShortcutDimensionForNotLinkedSIEDimension()
    var
        Dimension: Record Dimension;
        GeneralLedgerSetup: Record "General Ledger Setup";
        SIEDimension: Record "SIE Dimension";
    begin
        // [FEATURE] [Standard Import Export] [Dimensions]
        // [SCENARIO 381234] Changing of Shortcut dimension updates ShortCutDimNo in SIE Dimension
        Initialize();

        // [GIVEN] SIE Dimension "D" not linked to any Shortcut Dimension
        LibraryDimension.CreateDimension(Dimension);
        SIEDimension.Validate("Dimension Code", Dimension.Code);
        SIEDimension.Insert(true);
        SIEDimension.TestField(ShortCutDimNo, 0);

        // [WHEN] Set dimension "D" as Shortcut Dimension 3 in G/L Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Shortcut Dimension 3 Code", Dimension.Code);
        GeneralLedgerSetup.Modify(true);

        // [THEN] SIE Dimension "D" linked with ShortCutDimNo = 3
        SIEDimension.Find();
        SIEDimension.TestField(ShortCutDimNo, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIEClearShortcutDimensionForLinkedSIEDimension()
    var
        Dimension: Record Dimension;
        GeneralLedgerSetup: Record "General Ledger Setup";
        SIEDimension: Record "SIE Dimension";
    begin
        // [FEATURE] [Standard Import Export] [Dimensions]
        // [SCENARIO 381234] Deleting of Shortcut dimension clears ShortCutDimNo in SIE Dimension to 0
        Initialize();

        // [GIVEN] Shortcut Dimension 4 has value dimension "D"
        LibraryDimension.CreateDimension(Dimension);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Shortcut Dimension 4 Code", Dimension.Code);
        GeneralLedgerSetup.Modify();

        // [GIVEN] SIE Dimension "D" linked to Shortcut Dimension 4
        SIEDimension.Validate("Dimension Code", Dimension.Code);
        SIEDimension.Insert(true);
        SIEDimension.TestField(ShortCutDimNo, 4);

        // [WHEN] Clear Shortcut Dimension 4 in G/L Setup
        GeneralLedgerSetup.Validate("Shortcut Dimension 4 Code", '');
        GeneralLedgerSetup.Modify(true);

        // [THEN] SIE Dimension "D" has ShortCutDimNo = 0
        SIEDimension.Find();
        SIEDimension.TestField(ShortCutDimNo, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIEReplaceShortcutDimensionForTwoSIEDimentios()
    var
        Dimension1: Record Dimension;
        Dimension2: Record Dimension;
        GeneralLedgerSetup: Record "General Ledger Setup";
        SIEDimension1: Record "SIE Dimension";
        SIEDimension2: Record "SIE Dimension";
    begin
        // [FEATURE] [Standard Import Export] [Dimensions]
        // [SCENARIO 381234] Replacing of Shortcut dimension updates ShortCutDimNo in SIE Dimension
        Initialize();

        // [GIVEN] Shortcut Dimension 5 has dimension "D1"
        LibraryDimension.CreateDimension(Dimension1);
        LibraryDimension.CreateDimension(Dimension2);

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Shortcut Dimension 5 Code", Dimension1.Code);
        GeneralLedgerSetup.Modify(true);

        // SIE Dimension "D1" is linked to Shortcut Dimension 5
        SIEDimension1.Validate("Dimension Code", Dimension1.Code);
        SIEDimension1.Insert(true);
        SIEDimension1.TestField(ShortCutDimNo, 5);
        // SIE Dimension "D2" is not linked to any Shortcut Dimension
        SIEDimension2.Validate("Dimension Code", Dimension2.Code);
        SIEDimension2.Insert(true);
        SIEDimension2.TestField(ShortCutDimNo, 0);

        // [WHEN] Replace Shortcut Dimension 5 with dimension "D2"
        GeneralLedgerSetup.Validate("Shortcut Dimension 5 Code", Dimension2.Code);
        GeneralLedgerSetup.Modify(true);

        // [THEN] SIE Dimension "D1" has ShortCutDimNo = 0
        // [THEN] SIE Dimension "D2" has ShortCutDimNo = 5
        SIEDimension1.Find();
        SIEDimension1.TestField(ShortCutDimNo, 0);
        SIEDimension2.Find();
        SIEDimension2.TestField(ShortCutDimNo, 5);
    end;
#endif

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        isInitialized := true;
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(100, 2));  // Using Random ofr Quantity.
    end;

    local procedure RunSalesReport(DocumentType: Enum "Sales Document Type"; No: Code[20]; ReportID: Integer)
    begin
        Commit();
        LibraryVariableStorage.Enqueue(DocumentType);
        LibraryVariableStorage.Enqueue(No);
        REPORT.Run(ReportID);
    end;

    local procedure UpdateCompanyInformation(var CompanyInformation: Record "Company Information"; RegisteredOffice: Text[20])
    begin
        CompanyInformation.Validate("Registered Office", RegisteredOffice);
        CompanyInformation.Modify(true);
    end;

    local procedure VerifyReportValue(FieldCaption: Text[50]; CaptionValue: Text[50]; FieldCaption3: Text[50]; CaptionValue3: Text[50])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(FieldCaption, CaptionValue);
        LibraryReportDataset.AssertElementWithValueExists(FieldCaption3, CaptionValue3);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesQuoteReportHandler(var StandardSalesQuote: TestRequestPage "Standard Sales - Quote")
    var
        DocumentType: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentType);
        LibraryVariableStorage.Dequeue(No);
        StandardSalesQuote.Header.SetFilter("Document Type", Format(DocumentType));
        StandardSalesQuote.Header.SetFilter("No.", No);
        StandardSalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
#endif