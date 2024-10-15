codeunit 142039 "UT REP Intrastat DE"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Intrastat] [Report]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        IntrastatJnlTemplateName: Code[10];
        IntrastatJnlBatchName: Code[10];
        HeaderText: Label 'All amounts are in %1';
        IntrastatJnlLineTotalWeightRoundedTxt: Label 'Intrastat_Jnl__Line__Total_Weight_Rounded_';
        SumTotalWeight: Label 'SumTotalWeight';
        IsInitialized: Boolean;
        SumTotalWeightRoundedTxt: Label 'SumTotalWeightRounded';

    [Test]
    [HandlerFunctions('IntrastatItemListReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ItemListReportOnPreDataItemTariffNo()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Intrastat - Item List]
        // [SCENARIO] Tariff Number when run REP 11001 "Intrastat - Item List"

        // Setup: Create Item with Tariff No.
        CreateItemWithTariffNumber(Item);

        // Exercise: Run Report Intrastat Item List.
        RunIntrastatItemListReport(Item."Tariff No.");

        // Verify: Verify the correct Tariff No occurs on Report Intrastat Item List.
        VerifyIntrastatReport(StrSubstNo('No_TariffNumber'), Item."Tariff No.");
    end;

    [Test]
    [HandlerFunctions('IntrastatFormDERequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatFormDEReportOnAfterGetRecordOriginCountryCode()
    var
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat - Form DE]
        // [SCENARIO] "Country/Region of Origin Code" when run REP 11012 "Intrastat - Form DE"

        // Setup: Create Item with Tariff Number. Create Intrastat Journal Line.
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);

        // Exercise: Run Report Intrastat - Form DE.
        RunIntrastatFormDEReport(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);

        // Verify: Verify that Origin Country Code is correct on Intrastat Form DE Report.
        VerifyIntrastatReport(
          StrSubstNo('Intrastat_Jnl__Line_Country_Region_of_Origin_Code'),
          IntrastatJnlLine."Country/Region of Origin Code");
    end;

    [Test]
    [HandlerFunctions('IntrastatFormDERequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatFormDEReportOnAfterGetRecordSumTotalWeight()
    var
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat - Form DE]
        // [SCENARIO] "Total Weight" when run REP 11012 "Intrastat - Form DE"

        // Setup: Create Item with Tariff Number. Create Intrastat Journal Line.
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);

        // Exercise: Run Report Intrastat - Form DE.
        RunIntrastatFormDEReport(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);

        // Verify: Verify that Sum Total Weight is correct on Intrastat Form DE Report.
        VerifyIntrastatReport(SumTotalWeight, IntrastatJnlLine."Total Weight");
    end;

    [Test]
    [HandlerFunctions('IntrastatFormDERequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatFormDEReportOnAfterGetRecordAdditionalReportingCurrency()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat - Form DE]
        // [SCENARIO] Additional Reporting Currency when run REP 11012 "Intrastat - Form DE"

        // Setup: Update Additional Reporting Currency and LCY Code on General Ledger Setup.
        UpdateGeneralLedgerSetup;

        // Create Item with Tariff Number. Create Intrastat Journal Line.
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);

        // Exercise: Run Report Intrastat - Form DE.
        RunIntrastatFormDEReport(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);

        // Verify: Verify Additional Reporting Currency of General Ledger Setup is updated on Intrastat Form DE Report.
        GeneralLedgerSetup.Get();
        VerifyIntrastatDEReport(StrSubstNo(HeaderText, GeneralLedgerSetup."Additional Reporting Currency"));
    end;

    [Test]
    [HandlerFunctions('IntrastatFormDERequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatFormDEReportOnAfterGetRecordLCYCode()
    var
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [Intrastat - Form DE]
        // [SCENARIO] LCY Code when run REP 11012 "Intrastat - Form DE"

        // Setup: Create Item with Tariff Number. Create Intrastat Journal Line.
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);

        // Exercise: Run Report Intrastat - Form DE.
        RunIntrastatFormDEReport(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);

        // Verify: Verify LCY Code of General Ledger Setup is updated on Intrastat Form DE Report.
        GeneralLedgerSetup.Get();
        VerifyIntrastatDEReport(StrSubstNo(HeaderText, GeneralLedgerSetup."LCY Code"));
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistDERequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatChecklistDEReportOnAfterGetRecordAdditionalReportingCurrency()
    var
        Item: Record Item;
        GeneralLedgerSetup: Record "General Ledger Setup";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat - Checklist DE]
        // [SCENARIO] Additional Reporting Currency when run REP 11013 "Intrastat - Checklist DE"

        // Setup: Update Additional Reporting Currency and LCY Code on General Ledger Setup.
        UpdateGeneralLedgerSetup;

        // Create Item with Tariff Number. Create Intrastat Journal Line.
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);

        // Exercise: Run Report Intrastat - Checklist DE.
        REPORT.Run(REPORT::"Intrastat - Checklist DE");

        // Verify: Verify Additional Reporting Currency of General Ledger Setup is updated on Intrastat Checklist DE Report.
        GeneralLedgerSetup.Get();
        VerifyIntrastatDEReport(StrSubstNo(HeaderText, GeneralLedgerSetup."Additional Reporting Currency"));
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistDERequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatChecklistDEReportOnAfterGetRecordLCYCode()
    var
        Item: Record Item;
        GeneralLedgerSetup: Record "General Ledger Setup";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat - Checklist DE]
        // [SCENARIO] LCY Code when run REP 11013 "Intrastat - Checklist DE"

        // Setup: Create Item with Tariff Number. Create Intrastat Journal Line.
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);

        // Exercise: Run Report Intrastat - Checklist DE.
        REPORT.Run(REPORT::"Intrastat - Checklist DE");

        // Verify: Verify LCY Code of General Ledger Setup is updated on Intrastat Checklist DE Report.
        GeneralLedgerSetup.Get();
        VerifyIntrastatDEReport(StrSubstNo(HeaderText, GeneralLedgerSetup."LCY Code"));
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistDERequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatChecklistDEReportOnAftergetRecordSumTotalWeight()
    var
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat - Checklist DE]
        // [SCENARIO] "Total Weight" when run REP 11013 "Intrastat - Checklist DE"

        // Setup: Update LCY Code on General Ledger Setup. Create Item with Tariff Number. Create Intrastat Journal Line.
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);

        // Exercise: Run Report Intrastat - Checklist DE.
        REPORT.Run(REPORT::"Intrastat - Checklist DE");

        // Verify: Verify Sum Total Weight on Intrastat Checklist DE Report.
        VerifyIntrastatReport(SumTotalWeight, IntrastatJnlLine."Total Weight");
    end;

    [Test]
    [HandlerFunctions('IntrastatFormDERequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatFormDEReportOnAfterGetRecordShipment()
    var
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat - Form DE]
        // [SCENARIO] "Country/Region Code" and "Total Weight" when run REP 11012 "Intrastat - Form DE"

        // Setup: Create Item with Tariff Number. Create Intrastat Journal Line.
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);

        // Exercise: Run Report Intrastat - Form DE.
        RunIntrastatFormDEReport(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);

        // Verify: Verify that Country Region Of Origin Code and Total Weight is correct on Intrastat Form DE Report.
        VerifyIntrastatReport('Intrastat_Jnl__Line_Country_Region_of_Origin_Code', IntrastatJnlLine."Country/Region of Origin Code");
        LibraryReportDataset.AssertElementWithValueExists('Intrastat_Jnl__Line__Total_Weight_', IntrastatJnlLine."Total Weight");
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistDERequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatChecklistDEReportOnAfterGetRecordOriginCountryCode()
    var
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat - Checklist DE]
        // [SCENARIO] "Country/Region Code" when run REP 11013 "Intrastat - Checklist DE"
        // [SCENARIO 392541] "Partner VAT ID" is printed

        // Setup: Create Item with Tariff Number. Create Intrastat Journal Line.
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);

        // Exercise: Run Report Intrastat - Checklist DE.
        REPORT.Run(REPORT::"Intrastat - Checklist DE");

        // Verify: Verify that Country Region Origin Code is correct on Intrastat Checklist DE Report.
        VerifyIntrastatReport('Intrastat_Jnl__Line_Country_Region_of_Origin_Code', IntrastatJnlLine."Country/Region of Origin Code");
        LibraryReportDataset.AssertElementWithValueExists('Intrastat_Jnl_Line_Partner_VAT_ID', IntrastatJnlLine."Partner VAT ID");
    end;

    [Test]
    [HandlerFunctions('IntrastatFormDERequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatFormDEReportOnAfterGetRecordItemOriginCountryCode()
    var
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat - Form DE]
        // [SCENARIO] Item."Country/Region of Origin Code" when run REP 11012 "Intrastat - Form DE"

        // Setup: Create Item with Tariff Number. Create Intrastat Journal Line. Update Country Region Of Origin Code on Item.
        CreateItemWithTariffNumber(Item);
        Item."Country/Region of Origin Code" := CreateCountryRegion;
        Item.Modify();
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);
        IntrastatJnlLine.Validate("Item No.", Item."No.");  // Validate required to invoke the Item No OnValidate Trigger.
        IntrastatJnlLine.Modify();

        // Exercise: Run Report Intrastat - Form DE.
        RunIntrastatFormDEReport(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);

        // Verify: Verify that Country Region Of Origin Code is correct on Intrastat Form DE Report.
        VerifyIntrastatReport('Intrastat_Jnl__Line_Country_Region_of_Origin_Code', Item."Country/Region of Origin Code");
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistDERequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatChecklistDEReportOnAfterGetRecordTotalWeight()
    var
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat - Checklist DE]
        // [SCENARIO] "Net Weight" when run REP 11013 "Intrastat - Checklist DE"

        // Setup: Create Item with Tariff Number. Update Net Weight on Item. Create Intrastat Journal Line.
        CreateItemWithTariffNumber(Item);
        Item."Net Weight" := 1;
        Item.Modify();
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);
        IntrastatJnlLine.Validate(Quantity, 1);  // Validate required to invoke the Quantity OnValidate Trigger.

        // Exercise: Run Report Intrastat - Checklist DE.
        REPORT.Run(REPORT::"Intrastat - Checklist DE");

        // Verify: Verify that Total Weight is Item Net Weight on Intrastat Checklist DE Report.
        VerifyIntrastatReport('Intrastat_Jnl__Line__Total_Weight_', Item."Net Weight");
    end;

    [Test]
    [HandlerFunctions('IntrastatFormDERequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatFormDEReportOnAfterGetRecordSingleEntryShipment()
    var
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat - Form DE]
        // [SCENARIO] "Statistical Value" when run REP 11012 "Intrastat - Form DE"

        // Setup: Create Item with Tariff Number. Create Intrastat Journal Line.
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);

        // Update Amount on Intrastat Journal Line.
        IntrastatJnlLine.Validate(Amount, 1);  // Validate required to get Statistical Value on Intrastat Journal Line.
        IntrastatJnlLine.Modify();

        // Exercise: Run Report Intrastat - Form DE.
        RunIntrastatFormDEReport(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);

        // Verify: Verify that Statistical Value and No Of Entries are correct on Intrastat Form DE Report.
        VerifyIntrastatReport('Intrastat_Jnl__Line__Statistical_Value_', IntrastatJnlLine."Statistical Value");
        LibraryReportDataset.AssertElementWithValueExists('NoOfRecords', 1);
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistDERequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatChecklistDEReportOnAfterGetRecordSingleEntryShipment()
    var
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat - Checklist DE]
        // [SCENARIO] "Statistical Value" when run REP 11013 "Intrastat - Checklist DE"

        // Setup: Create Item with Tariff Number. Create Intrastat Journal Line.
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);

        // Update Amount on Intrastat Journal Line.
        IntrastatJnlLine.Validate(Amount, 1);  // Validate required to get Statistical Value on Intrastat Journal Line.
        IntrastatJnlLine.Modify();

        // Exercise: Run Report Intrastat - Checklist DE.
        REPORT.Run(REPORT::"Intrastat - Checklist DE");

        // Verify: Verify that Statistical Value and No Of Entries are correct on Intrastat Checklist DE Report.
        VerifyIntrastatReport('Intrastat_Jnl__Line__Statistical_Value_', IntrastatJnlLine."Statistical Value");
        LibraryReportDataset.AssertElementWithValueExists('NoOfRecords', 1);
    end;

    [Test]
    [HandlerFunctions('IntrastatFormDERequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatFormDE_OriginCountryIntrastatCode_Shipment()
    var
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat - Form DE] [Shipment]
        // [SCENARIO 258143] Origin country "Intrastat Code" when run REP 11012 "Intrastat - Form DE" for the Intrastat Journal Shipment line

        // [GIVEN] Intrastat Journal Line with Type = Shipment
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);

        // [WHEN] Run Report 11012 "Intrastat - Form DE"
        RunIntrastatFormDEReport(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);

        // [THEN] Origin Country Intrastat Code = ""
        VerifyIntrastatReport('OriginCountry__Intrastat_Code_', '');
    end;

    [Test]
    [HandlerFunctions('IntrastatFormDERequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatFormDE_OriginCountryIntrastatCode_Receipt()
    var
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        CountryRegion: Record "Country/Region";
    begin
        // [FEATURE] [Intrastat - Form DE] [Receipt]
        // [SCENARIO 258143] Origin country "Intrastat Code" when run REP 11012 "Intrastat - Form DE" for the Intrastat Journal Receipt line

        // [GIVEN] "Country/Region" = "X" with "Intrastat Code" = "Y"
        // [GIVEN] Intrastat Journal Line with Type = Receipt, "Country/Region of Origin Code" = "X"
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);
        IntrastatJnlLine.Validate("Item No.", Item."No.");  // Validate required for Origin Country Code.
        IntrastatJnlLine.Modify();

        // [WHEN] Run Report 11012 "Intrastat - Form DE"
        RunIntrastatFormDEReport(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);

        // [THEN] Origin Country Intrastat Code = "Y"
        CountryRegion.Get(IntrastatJnlLine."Country/Region of Origin Code");
        VerifyIntrastatReport('OriginCountry__Intrastat_Code_', CountryRegion."Intrastat Code");
    end;

    [Test]
    [HandlerFunctions('IntrastatFormDERequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatFormDE_OriginCountryIntrastatCode_Receipt_BlankedIntrastatCode()
    var
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat - Form DE] [Receipt]
        // [SCENARIO 258143] Origin country "Intrastat Code" when run REP 11012 "Intrastat - Form DE" for the Intrastat Journal Receipt line
        // [SCENARIO 258143] in case of blanked origin country "Intrastat Code"

        // [GIVEN] "Country/Region" = "X" with "Intrastat Code" = ""
        // [GIVEN] Intrastat Journal Line with Type = Receipt, "Country/Region of Origin Code" = "X"
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);
        ModifyCountryRegionIntrastatCode(IntrastatJnlLine."Country/Region of Origin Code", '');

        // [WHEN] Run Report 11012 "Intrastat - Form DE"
        RunIntrastatFormDEReport(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);

        // [THEN] Origin Country Intrastat Code = "X"
        VerifyIntrastatReport('OriginCountry__Intrastat_Code_', IntrastatJnlLine."Country/Region of Origin Code");
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistDERequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatChecklistDE_OriginCountryIntrastatCode_Shipment()
    var
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat - Checklist DE] [Shipment]
        // [SCENARIO 258143] Origin country "Intrastat Code" when run REP 11013 "Intrastat - Checklist DE" for the Intrastat Journal Shipment line

        // [GIVEN] Intrastat Journal Line with Type = Shipment
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);

        // [WHEN] Run Report 11013 "Intrastat - Checklist DE"
        REPORT.Run(REPORT::"Intrastat - Checklist DE");

        // [THEN] Origin Country Intrastat Code = ""
        VerifyIntrastatReport('OriginCountry__Intrastat_Code_', IntrastatJnlLine."Country/Region of Origin Code");
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistDERequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatChecklistDE_OriginCountryIntrastatCode_Receipt()
    var
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        CountryRegion: Record "Country/Region";
    begin
        // [FEATURE] [Intrastat - Checklist DE] [Receipt]
        // [SCENARIO 258143] Origin country "Intrastat Code" when run REP 11013 "Intrastat - Checklist DE" for the Intrastat Journal Receipt line

        // [GIVEN] "Country/Region" = "X" with "Intrastat Code" = "Y"
        // [GIVEN] Intrastat Journal Line with Type = Receipt, "Country/Region of Origin Code" = "X"
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);

        // [WHEN] Run Report 11013 "Intrastat - Checklist DE"
        REPORT.Run(REPORT::"Intrastat - Checklist DE");

        // [THEN] Origin Country Intrastat Code = "Y"
        CountryRegion.Get(IntrastatJnlLine."Country/Region of Origin Code");
        VerifyIntrastatReport('OriginCountry__Intrastat_Code_', CountryRegion."Intrastat Code");
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistDERequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatChecklistDE_OriginCountryIntrastatCode_Receipt_BlankedIntrastatCode()
    var
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Intrastat - Checklist DE] [Receipt]
        // [SCENARIO 258143] Origin country "Intrastat Code" when run REP 11013 "Intrastat - Checklist DE" for the Intrastat Journal Receipt line
        // [SCENARIO 258143] in case of blanked origin country "Intrastat Code"

        // [GIVEN] "Country/Region" = "X" with "Intrastat Code" = ""
        // [GIVEN] Intrastat Journal Line with Type = Receipt, "Country/Region of Origin Code" = "X"
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);
        ModifyCountryRegionIntrastatCode(IntrastatJnlLine."Country/Region of Origin Code", '');

        // [WHEN] Run Report 11013 "Intrastat - Checklist DE"
        REPORT.Run(REPORT::"Intrastat - Checklist DE");

        // [THEN] Origin Country Intrastat Code = "X"
        VerifyIntrastatReport('OriginCountry__Intrastat_Code_', IntrastatJnlLine."Country/Region of Origin Code");
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistDEExcelRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatChecklistDECalledFromJournalMultiBatch()
    var
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Checklist DE]
        // [SCENARIO 361991] Intrastat - Checklist DE exported when called from Journal with multiple batches
        Initialize();

        // [GIVEN] Intrastat Journal Template with Batches "X" and "Y". Intrastat Journal Line in Batch "Y".
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Receipt);
        EnqueueJournalBatchTemplate(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        LibraryReportValidation.SetFileName(IntrastatJnlLine."Journal Template Name");

        // [WHEN] Intrastat - Checklist DE report run from Intrastat Journal Page Batch "Y"
        REPORT.Run(REPORT::"Intrastat - Checklist DE");

        // [THEN] Intrastat - Checklist DE successfully exported
        LibraryUtility.CheckFileNotEmpty(LibraryReportValidation.GetFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IntrastatExportMgtDACH_GetOriginCountryCode()
    var
        CountryRegion: Record "Country/Region";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 258143] COD 11002 "Intrastat - Export Mgt. DACH".GetOriginCountryCode() returns country's "Intrastat Code"
        // [SCENARIO 258143] if it is not blanked and country's Code otherwise
        CountryRegion.Get(CreateCountryRegion);
        Assert.AreEqual(CountryRegion."Intrastat Code", IntrastatExportMgtDACH.GetOriginCountryCode(CountryRegion.Code), '');

        ModifyCountryRegionIntrastatCode(CountryRegion.Code, '');
        Assert.AreEqual(CountryRegion.Code, IntrastatExportMgtDACH.GetOriginCountryCode(CountryRegion.Code), '');
    end;

    [Test]
    [HandlerFunctions('IntrastatFormDERequestPageHandler')]
    [Scope('OnPrem')]
    procedure IntrastatFormDEReportOnAfterGetRecordSumTotalWeightRounded()
    var
        Item: Record Item;
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: array[2] of Record "Intrastat Jnl. Line";
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        TotalWeight: Decimal;
    begin
        // [FEATURE] [Intrastat - Form DE]
        // [SCENARIO 327050] In REP 11012 "Intrastat - Form DE" SumTotalWeightRounded and SubTotalWeight are rounded.

        // [GIVEN] Two Intrastat Journal Lines with "Total Weight" 0.8.
        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlTemplate, IntrastatJnlBatch);
        TotalWeight := LibraryRandom.RandDecInDecimalRange(0.8, 0.9, 1);
        CreateIntrastatJournalLineWithTotalWeight(Item, IntrastatJnlLine[1], IntrastatJnlLine[1].Type::Receipt, TotalWeight);
        LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine[2], IntrastatJnlTemplateName, IntrastatJnlBatchName);
        IntrastatJnlLine[2].TransferFields(IntrastatJnlLine[1], false);
        IntrastatJnlLine[2].Modify();

        // [WHEN] Report "Intrastat - Form DE" is run.
        Commit();
        RunIntrastatFormDEReport(IntrastatJnlLine[1], IntrastatJnlLine[1].Type::Receipt);

        // [THEN] Resulting dataset contains SumTotalWeightRounded ROUND(0.8 * 2) = 2 and Intrastat_Jnl__Line__Total_Weight_Rounded ROUND(0.8 * 2) = 2.
        VerifyIntrastatReport(SumTotalWeightRoundedTxt, Round(TotalWeight * 2, 1));
        LibraryReportDataset.AssertElementWithValueExists(IntrastatJnlLineTotalWeightRoundedTxt, Round(TotalWeight * 2, 1));
    end;

#if not CLEAN19
    [Test]
    [HandlerFunctions('IntrastatChecklistDERequestPageHandler')]
    procedure CheckForPartnerVATID()
    var
        CompanyInformation: Record "Company Information";
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [SCENARIO 392540] "Intrastat - Checklist DE" report checks shipment for "Partner VAT ID" if enabled in company information
        Initialize();

        CompanyInformation.Get();
        CompanyInformation.TestField("Check for Partner VAT ID", true);

        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);
        IntrastatJnlLine."Partner VAT ID" := '';
        IntrastatJnlLine.Modify();

        Commit();
        asserterror Report.Run(Report::"Intrastat - Checklist DE");

        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError('Partner VAT ID');
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistDERequestPageHandler')]
    procedure CheckForCountryOfOrigin()
    var
        CompanyInformation: Record "Company Information";
        Item: Record Item;
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [SCENARIO 392540] "Intrastat - Checklist DE" report checks shipment for "Check for Country of Origin" if enabled in company information
        Initialize();

        CompanyInformation.Get();
        CompanyInformation.TestField("Check for Country of Origin", true);

        CreateItemWithTariffNumber(Item);
        CreateIntrastatJournalLine(Item, IntrastatJnlLine, IntrastatJnlLine.Type::Shipment);
        IntrastatJnlLine."Country/Region of Origin Code" := '';
        IntrastatJnlLine.Modify();

        Commit();
        asserterror Report.Run(Report::"Intrastat - Checklist DE");

        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError('Country/Region of Origin Code');
    end;

    [Test]
    procedure CompanyInformationDefaultValues()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO 392540] Company information default values for "Check for Partner VAT ID", "Check for Country of Origin"
        CompanyInformation.Init();
        CompanyInformation.TestField("Check for Partner VAT ID", true);
        CompanyInformation.TestField("Check for Country of Origin", true);
    end;
#endif

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        UpdateReceiptsShipmentsOnIntrastatSetup(true, true);
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(Database::"Intrastat Setup");

        IsInitialized := true;
    end;

    local procedure RunIntrastatItemListReport(TariffNo: Code[10])
    var
        TariffNumber: Record "Tariff Number";
        IntrastatItemList: Report "Intrastat - Item List";
    begin
        TariffNumber.SetRange("No.", TariffNo);
        IntrastatItemList.SetTableView(TariffNumber);
        IntrastatItemList.Run();  // Invokes IntrastatItemListReportHandler.
    end;

    local procedure RunIntrastatFormDEReport(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; Type: Option)
    var
        IntrastatFormDE: Report "Intrastat - Form DE";
    begin
        IntrastatJnlLine.SetRange(Type, Type);
        IntrastatFormDE.SetTableView(IntrastatJnlLine);
        IntrastatFormDE.Run();  // Invokes IntrastatFormDERequestPageHandler.
    end;

    local procedure CreateItemWithTariffNumber(var Item: Record Item)
    var
        TariffNumber: Record "Tariff Number";
    begin
        TariffNumber."No." := LibraryUTUtility.GetNewCode10;
        TariffNumber.Insert();
        Item."No." := LibraryUTUtility.GetNewCode10;
        Item.Insert();
        Item."Tariff No." := TariffNumber."No.";
        Item.Modify();
    end;

    local procedure CreateCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Init();
        CountryRegion.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCodeWithLength(
              CountryRegion.FieldNo(Code), DATABASE::"Country/Region", 3),
            1, 3));
        CountryRegion.Validate("Intrastat Code", CountryRegion.Code);
        CountryRegion.Insert(true);
        exit(CountryRegion.Code);
    end;

    local procedure CreateIntrastatJournalTemplateAndBatch(var IntrastatJnlTemplate: Record "Intrastat Jnl. Template"; var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    begin
        IntrastatJnlTemplate.Name := LibraryUTUtility.GetNewCode10;
        IntrastatJnlTemplate."Page ID" := PAGE::"Intrastat Journal";
        IntrastatJnlTemplate."Checklist Report ID" := REPORT::"Intrastat - Checklist DE";
        IntrastatJnlTemplate.Insert();
        IntrastatJnlTemplateName := IntrastatJnlTemplate.Name;  // Assign value to global variable.

        IntrastatJnlBatch."Journal Template Name" := IntrastatJnlTemplate.Name;
        IntrastatJnlBatch.Name := LibraryUTUtility.GetNewCode10;
        IntrastatJnlBatch."Currency Identifier" := LibraryUTUtility.GetNewCode10;
        IntrastatJnlBatch.Insert();
        IntrastatJnlBatchName := IntrastatJnlBatch.Name;  // Assign value to global variable.
    end;

    local procedure CreateIntrastatJournalLine(var Item: Record Item; var IntrastatJnlLine: Record "Intrastat Jnl. Line"; Type: Option)
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        // Create Country Region. Create Intrastat Journal Template and Batch.
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlTemplate, IntrastatJnlBatch);

        IntrastatJnlLine."Journal Template Name" := IntrastatJnlTemplateName;
        IntrastatJnlLine."Journal Batch Name" := IntrastatJnlBatchName;
        IntrastatJnlLine."Line No." := 1;
        IntrastatJnlLine.Insert();

        IntrastatJnlLine.Type := Type;
        IntrastatJnlLine."Partner VAT ID" := LibraryUtility.GenerateGUID();
        IntrastatJnlLine.Area := LibraryUTUtility.GetNewCode10;
        IntrastatJnlLine."Item No." := Item."No.";
        IntrastatJnlLine.Quantity := 1;
        IntrastatJnlLine."Transaction Type" := LibraryUTUtility.GetNewCode10;
        IntrastatJnlLine."Transport Method" := LibraryUTUtility.GetNewCode10;
        IntrastatJnlLine."Transaction Specification" := LibraryUTUtility.GetNewCode10;
        IntrastatJnlLine."Tariff No." := Item."Tariff No.";
        IntrastatJnlLine."Country/Region Code" := CreateCountryRegion;
        IntrastatJnlLine."Country/Region of Origin Code" := CreateCountryRegion;
        IntrastatJnlLine."Total Weight" := 1;
        IntrastatJnlLine.Date := WorkDate;
        IntrastatJnlLine.Modify();
    end;

    local procedure CreateIntrastatJournalLineWithTotalWeight(var Item: Record Item; var IntrastatJnlLine: Record "Intrastat Jnl. Line"; Type: Option; TotalWeight: Decimal)
    begin
        LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlTemplateName, IntrastatJnlBatchName);

        IntrastatJnlLine.Type := Type;
        IntrastatJnlLine.Area := LibraryUTUtility.GetNewCode10;
        IntrastatJnlLine."Item No." := Item."No.";
        IntrastatJnlLine.Quantity := 1;
        IntrastatJnlLine."Transaction Type" := LibraryUTUtility.GetNewCode10;
        IntrastatJnlLine."Transport Method" := LibraryUTUtility.GetNewCode10;
        IntrastatJnlLine."Transaction Specification" := LibraryUTUtility.GetNewCode10;
        IntrastatJnlLine."Tariff No." := Item."Tariff No.";
        IntrastatJnlLine."Country/Region Code" := CreateCountryRegion;
        IntrastatJnlLine."Country/Region of Origin Code" := CreateCountryRegion;
        IntrastatJnlLine."Total Weight" := TotalWeight;
        IntrastatJnlLine.Date := WorkDate;
        IntrastatJnlLine.Modify();
    end;

    local procedure ModifyCountryRegionIntrastatCode(CountryRegionCode: Code[10]; NewIntrastatCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        with CountryRegion do begin
            Get(CountryRegionCode);
            Validate("Intrastat Code", NewIntrastatCode);
            Modify(true);
        end;
    end;

    local procedure EnqueueJournalBatchTemplate(JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        LibraryVariableStorage.Enqueue(JournalTemplateName);
        LibraryVariableStorage.Enqueue(JournalTemplateName);
        LibraryVariableStorage.Enqueue(JournalBatchName);
    end;

    local procedure UpdateGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := GeneralLedgerSetup."LCY Code";
        GeneralLedgerSetup.Modify();
    end;

    local procedure UpdateReceiptsShipmentsOnIntrastatSetup(ReportReceipts: Boolean; ReportShipments: Boolean)
    var
        IntrastatSetup: Record "Intrastat Setup";
    begin
        IntrastatSetup.Get();
        IntrastatSetup."Report Receipts" := ReportReceipts;
        IntrastatSetup."Report Shipments" := ReportShipments;
        IntrastatSetup.Modify();
    end;

    local procedure VerifyIntrastatReport(ElementName: Text; ExpectedValue: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(ElementName, ExpectedValue);
    end;

    local procedure VerifyIntrastatDEReport(HeaderText: Text[30])
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('HeaderText', HeaderText);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatChecklistDERequestPageHandler(var IntrastatChecklistDE: TestRequestPage "Intrastat - Checklist DE")
    begin
        IntrastatChecklistDE."Intrastat Jnl. Batch".SetFilter("Journal Template Name", IntrastatJnlTemplateName);
        IntrastatChecklistDE."Intrastat Jnl. Batch".SetFilter(Name, IntrastatJnlBatchName);
        IntrastatChecklistDE.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatFormDERequestPageHandler(var IntrastatFormDE: TestRequestPage "Intrastat - Form DE")
    begin
        IntrastatFormDE."Intrastat Jnl. Batch".SetFilter("Journal Template Name", IntrastatJnlTemplateName);
        IntrastatFormDE."Intrastat Jnl. Batch".SetFilter(Name, IntrastatJnlBatchName);
        IntrastatFormDE.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatItemListReportHandler(var IntrastatItemList: TestRequestPage "Intrastat - Item List")
    begin
        IntrastatItemList.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatChecklistDEExcelRequestPageHandler(var IntrastatChecklistDE: TestRequestPage "Intrastat - Checklist DE")
    begin
        IntrastatChecklistDE."Intrastat Jnl. Line".SetFilter("Journal Template Name", LibraryVariableStorage.DequeueText);
        IntrastatChecklistDE."Intrastat Jnl. Line".SetFilter("Journal Batch Name", LibraryVariableStorage.DequeueText);
        IntrastatChecklistDE.SaveAsExcel(LibraryReportValidation.GetFileName);
    end;

    local procedure ExtractEntryFromZipFile(ZipFilePath: Text; EntryName: Text; ExtractedEntryOutStream: OutStream; ExtractedEntryLength: Integer);
    var
        DataCompression: Codeunit "Data Compression";
        ZipFile: File;
        ZipFileInStream: InStream;
    begin
        ZipFile.Open(ZipFilePath);
        ZipFile.CreateInStream(ZipFileInStream);
        DataCompression.OpenZipArchive(ZipFileInStream, false);
        DataCompression.ExtractEntry(EntryName, ExtractedEntryOutStream, ExtractedEntryLength);
        DataCompression.CloseZipArchive();
        ZipFile.Close();
    end;
}

