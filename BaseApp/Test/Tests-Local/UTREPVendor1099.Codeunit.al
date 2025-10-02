#if not CLEAN25
codeunit 142055 "UT REP Vendor 1099"
{
    // Validate feature Vendor 1099.
    //  1. Verify Vendor 1099 Div report value.
    //  2. Verify Vendor 1099 Information report value.
    //  3. Verify Vendor 1099 Int report value.
    //  4. Verify Vendor 1099 Misc report value.
    // 
    //  Covers Test Cases for WI - 336173
    //  ----------------------------------------------------------------------------------------------
    //  Test Function Name                                                                      TFS ID
    //  ----------------------------------------------------------------------------------------------
    //  OnAfterGetRecordVendor1099Div                                                           171172
    //  OnAfterGetRecordVendor1099Information                                                   171171
    //  OnAfterGetRecordVendor1099Int                                                           171170
    //  OnAfterGetRecordVendor1099Misc                                                          171169

    Permissions = TableData "Vendor Ledger Entry" = imd,
                  TableData "Detailed Vendor Ledg. Entry" = imd;
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteReason = 'Moved to IRS Forms App.';
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';

    trigger OnRun()
    begin
        // [FEATURE] [UT] [Vendor 1099]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        Amounts: Label 'Amounts';
        GetAmtINT01: Label 'GetAmtINT01';
        GetAmtMISC02: Label 'GetAmtMISC02';
        GetAmtNEC01Tok: Label 'GetAmtNEC01';
        GetAmtDIV03Tok: Label 'GetAmtDIV03';
        GetAmtDIV13Tok: Label 'GetAmtDIV13';
        GetAmtCombinedDivCodeAB: Label 'GetAmtCombinedDivCodeAB';
        IRS1099CodeDiv: Label 'DIV-01-A';
        IRS1099CodeDiv02ETok: Label 'DIV-02-E';
        IRS1099CodeDiv02FTok: Label 'DIV-02-F';
        IRS1099CodeDiv12Tok: Label 'DIV-12';
        IRS1099CodeDiv13Tok: Label 'DIV-13';
        IRS1099CodeInt: Label 'INT-01';
        IRS1099CodeMisc: Label 'MISC-02';
        Assert: Codeunit Assert;
        LineSequenceNoErr: Label 'Wrong line Sequence No. value';
        IRS1099CodeMisc01Tok: Label 'MISC-01', Comment = 'MISC - miscellaneous';
        IRS1099CodeMisc05Tok: Label 'MISC-05', Comment = 'MISC - miscellaneous';
        IRS1099CodeMisc07Tok: Label 'MISC-07', Comment = 'MISC - miscellaneous';
        IRS1099CodeMisc09Tok: Label 'MISC-09', Comment = 'MISC - miscellaneous';
        IRS1099CodeMisc10Tok: Label 'MISC-10', Comment = 'MISC - miscellaneous';
        IRS1099CodeMisc11Tok: Label 'MISC-11', Comment = 'MISC - miscellaneous';
        IRS1099CodeMisc12Tok: Label 'MISC-12', Comment = 'MISC - miscellaneous';
        IRS1099CodeMisc14Tok: Label 'MISC-14', Comment = 'MISC - miscellaneous';
        IRS1099CodeNec01Tok: Label 'NEC-01';
        AmountCodeErr: Label 'Wrong value of Amount code.';
        LibraryLocalFunctionality: Codeunit "Library - Local Functionality";
        AmountErr: Label 'Wrong value of Amount.';
        UnkownCodeErr: Label 'Invoice %1 for vendor %2 has unknown 1099 code %3.', Comment = '%1 = document number;%2 = vendor number;%3 = IRS 1099 code.';
        UseNewIRSFormsFeatureMsg: Label 'Use the new IRS Forms feature';

    [HandlerFunctions('Vendor1099DivRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendor1099Div()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Purpose of the test is to validate trigger Vendor - OnAfterGetRecord of Report 10109.

        // Setup: Create Vendor and Detailed Leger Entry.
        Initialize();
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeDiv, LibraryRandom.RandIntInRange(100, 1000));

        // Exercise.
        REPORT.Run(REPORT::"Vendor 1099 Div");

        // Verify: Verify Vendor 1099 Div report value.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtCombinedDivCodeAB, -VendorLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('Vendor1099InformationRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendor1099Information()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Purpose of the test is to validate trigger Vendor - OnAfterGetRecord of Report 10109.

        // Setup: Create Vendor and Detailed Leger Entry.
        Initialize();
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeDiv, LibraryRandom.RandIntInRange(100, 1000));

        // Exercise.
        REPORT.Run(REPORT::"Vendor 1099 Information");

        // Verify: Verify Vendor 1099 Information report value.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Amounts, -VendorLedgerEntry.Amount);
    end;

    [HandlerFunctions('Vendor1099IntRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendor1099Int()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Purpose of the test is to validate trigger Vendor - OnAfterGetRecord of Report 10109.

        // Setup: Create Vendor and Detailed Leger Entry.
        Initialize();
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeInt, LibraryRandom.RandIntInRange(100, 1000));

        // Exercise.
        REPORT.Run(REPORT::"Vendor 1099 Int");

        // Verify: Verify Vendor 1099 Int report value.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtINT01, -VendorLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MiscRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVendor1099Misc()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Purpose of the test is to validate trigger Vendor - OnAfterGetRecord of Report 10109.

        // Setup: Create Vendor and Detailed Leger Entry.
        Initialize();
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeMisc, LibraryRandom.RandIntInRange(100, 1000));

        // Exercise.
        REPORT.Run(REPORT::"Vendor 1099 Misc");

        // Verify: Verify Vendor 1099 Misc report value.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtMISC02, -VendorLedgerEntry.Amount);
    end;

    [HandlerFunctions('Vendor1099DivRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099DivAppliedPaymentToThreeInvoices()
    var
        DocAmountSum: Decimal;
    begin
        // [SCENARIO 123991] Report 1099 Div when multiple  documents applied in a single transaction

        // [GIVEN] 2 vendors "A", "B"
        // [GIVEN] 3 invoices per vendor posted in different transactions.
        // [GIVEN] One payment per vendor applied to all 3 invoices and closed them within a single transaction
        Initialize();
        DocAmountSum := SetupMultipleDocScenario(IRS1099CodeDiv);

        // [WHEN] Run Report 1099 Div
        REPORT.Run(REPORT::"Vendor 1099 Div");

        // [THEN] Exported amount for vendor "A" equal to sum of invoices for "A"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtCombinedDivCodeAB, DocAmountSum);
    end;

    [Test]
    [HandlerFunctions('Vendor1099InformationRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099InformationAppliedPaymentThreeInvoices()
    var
        DocAmountSum: Decimal;
    begin
        // [SCENARIO 123991] Report 1099 Information when multiple  documents applied in a single transaction

        // [GIVEN] 2 vendors "A", "B"
        // [GIVEN] 3 invoices per vendor posted in different transactions.
        // [GIVEN] One payment per vendor applied to all 3 invoices and closed them within a single transaction
        Initialize();
        DocAmountSum := SetupMultipleDocScenario(IRS1099CodeDiv);

        // [WHEN] Run Report 1099 Information
        REPORT.Run(REPORT::"Vendor 1099 Information");

        // [THEN] Exported amount for vendor "A" equal to sum of invoices for "A"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Amounts, DocAmountSum);
    end;

    [HandlerFunctions('Vendor1099IntRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099IntAppliedPaymentToThreeInvoices()
    var
        DocAmountSum: Decimal;
    begin
        // [SCENARIO 123991] Report 1099 Int when multiple  documents applied in a single transaction

        // [GIVEN] 2 vendors "A", "B"
        // [GIVEN] 3 invoices per vendor posted in different transactions.
        // [GIVEN] One payment per vendor applied to all 3 invoices and closed them within a single transaction
        Initialize();
        DocAmountSum := SetupMultipleDocScenario(IRS1099CodeInt);

        // [WHEN] Run Report 1099 Int
        REPORT.Run(REPORT::"Vendor 1099 Int");

        // [THEN] Exported amount for vendor "A" equal to sum of invoices for "A"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtINT01, DocAmountSum);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MiscRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MiscAppliedPaymentToThreeInvoices()
    var
        DocAmountSum: Decimal;
    begin
        // [SCENARIO 123991] Report 1099 Misc when multiple  documents applied in a single transaction

        // [GIVEN] 2 vendors "A", "B"
        // [GIVEN] 3 invoices per vendor posted in different transactions.
        // [GIVEN] One payment per vendor applied to all 3 invoices and closed them within a single transaction
        Initialize();
        DocAmountSum := SetupMultipleDocScenario(IRS1099CodeMisc);

        // [WHEN] Run Report 1099 Misc
        REPORT.Run(REPORT::"Vendor 1099 Misc");

        // [THEN] Exported amount for vendor "A" equal to sum of invoices for "A"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtMISC02, DocAmountSum);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaDivCRecLineSequenceNo()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 364351] Vendor 1099 Magnetic Media "DivCRec" line has "Sequence No." element in position 500 with length 8
        Initialize();

        // [GIVEN] Vendor with "DivCRec" source data
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeDiv, LibraryRandom.RandIntInRange(100, 1000));

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] "DivCRec" line has "Sequence No." element in position 500 with length 8
        Assert.AreEqual(
          '00000004',
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 4, 500, 8),
          LineSequenceNoErr);

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaIntCRecLineSequenceNo()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 364351] Vendor 1099 Magnetic Media "IntCRec" line has "Sequence No." element in position 500 with length 8
        Initialize();

        // [GIVEN] Vendor with "IntCRec" source data
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeInt, LibraryRandom.RandIntInRange(100, 1000));

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] "DivCRec" line has "Sequence No." element in position 500 with length 8
        Assert.AreEqual(
          '00000004',
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 4, 500, 8),
          LineSequenceNoErr);

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaMiscCRecLineSequenceNo()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 364351] Vendor 1099 Magnetic Media "MiscCRec" line has "Sequence No." element in position 500 with length 8
        Initialize();

        // [GIVEN] Vendor with "MiscCRec" source data
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeMisc, LibraryRandom.RandIntInRange(100, 1000));

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] "DivCRec" line has "Sequence No." element in position 500 with length 8
        Assert.AreEqual(
          '00000004',
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 4, 500, 8),
          LineSequenceNoErr);

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaDivFATCAIsSet()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO] The Div B record contains a flag, corresponding to the value of FATCA set on the vendor (true)
        Initialize();

        // [GIVEN] A Vendor which is marked as FACTA
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeDiv, LibraryRandom.RandIntInRange(100, 1000));
        Vendor.Get(VendorLedgerEntry."Vendor No.");
        Vendor."FATCA filing requirement" := true;
        Vendor.Modify();

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] The B record has value 1 at position 587
        Assert.AreEqual(
          '1',
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 3, 587, 1),
          LineSequenceNoErr);

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaDivFATCAIsNotSet()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO] The Div B record contains a flag, corresponding to the value of FATCA set on the vendor (false)
        Initialize();

        // [GIVEN] A Vendor which is not marked as FACTA
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeDiv, LibraryRandom.RandIntInRange(100, 1000));

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] The B record has value 0 at position 587
        Assert.AreEqual(
          '0',
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 3, 587, 1),
          LineSequenceNoErr);

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaIntFATCAIsSet()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO] The Int B record contains a flag, corresponding to the value of FATCA set on the vendor (true)
        Initialize();

        // [GIVEN] A Vendor which is marked as FACTA
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeInt, LibraryRandom.RandIntInRange(100, 1000));
        Vendor.Get(VendorLedgerEntry."Vendor No.");
        Vendor."FATCA filing requirement" := true;
        Vendor.Modify();

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] The B record has value 1 at position 600
        Assert.AreEqual(
          '1',
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 3, 600, 1),
          LineSequenceNoErr);

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaMiscFATCAIsSet()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO] The Misc B record contains a flag, corresponding to the value of FATCA set on the vendor (true)
        Initialize();

        // [GIVEN] A Vendor which is marked as FACTA
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeMisc, LibraryRandom.RandIntInRange(100, 1000));
        Vendor.Get(VendorLedgerEntry."Vendor No.");
        Vendor."FATCA filing requirement" := true;
        Vendor.Modify();

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] The B record has value 1 at position 548
        Assert.AreEqual(
          '1',
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 3, 548, 1),
          LineSequenceNoErr);

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaMisc07AmountCode()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 280534] The Misc A record have to contain Amount Code = 1 when Record B contains Direct Sales indicator and "IRS 1099 Code" = "MISC-07"
        Initialize();

        // [GIVEN] Vendor with "MiscARec" source data and MISC-07 code
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeMisc07Tok, LibraryRandom.RandIntInRange(5000, 10000)); // Amount have to be greater than 5000 For MISC-07
        Commit();

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] "MiscARec" line has "Amount Code" element in position 28 = '1'
        Assert.AreEqual('1', LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 2, 28, 1), AmountCodeErr);

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099DivRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099DivReportShowAmountWithAdjustment()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SecondVendorLedgerEntry: Record "Vendor Ledger Entry";
        IRS1099Adjustment: Record "IRS 1099 Adjustment";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 332661] A "Vendor 1099 Div" report shows the amount with adjustment

        Initialize();

        // [GIVEN] Vendor ledger entry for vendor "A" with "DIV-01-A" code, "Posting Date" = 01.01.2022 and total amount = 100
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeDiv, LibraryRandom.RandIntInRange(100, 1000));

        // [GIVEN] Vendor ledger entry for vendor "A" with "DIV-01-A" code, "Posting Date" = 01.01.2022 and total amount = 150
        // BUG 384664: Adjustment with multiple vendor ledger entries
        SetupToCreateLedgerEntriesForExistingVendor(
          SecondVendorLedgerEntry, VendorLedgerEntry."Vendor No.", IRS1099CodeDiv, LibraryRandom.RandIntInRange(1000, 2000));

        // [GIVEN] Adjustment amount equals 50 for vendor "A", code "DIV-01-A", Year = 2023
        LibraryLocalFunctionality.CreateIRS1099Adjustment(
          IRS1099Adjustment, VendorLedgerEntry."Vendor No.", IRS1099CodeDiv,
          Date2DMY(VendorLedgerEntry."Posting Date", 3) + 1, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Adjustment amount equals 30 for vendor "A", code "DIV-01-A", Year = 2022
        LibraryLocalFunctionality.CreateIRS1099Adjustment(
          IRS1099Adjustment, VendorLedgerEntry."Vendor No.", IRS1099CodeDiv,
          Date2DMY(VendorLedgerEntry."Posting Date", 3), LibraryRandom.RandDec(10, 2));

        // [THEN] Run "Vendor 1099 Div" report
        Vendor.SetRange("No.", VendorLedgerEntry."Vendor No.");
        REPORT.Run(REPORT::"Vendor 1099 Div", true, false, Vendor);

        // [THEN] Report has amount 280
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          GetAmtCombinedDivCodeAB, -VendorLedgerEntry.Amount - SecondVendorLedgerEntry.Amount + IRS1099Adjustment.Amount);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MiscRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MiscReportShowAmountWithAdjustment()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SecondVendorLedgerEntry: Record "Vendor Ledger Entry";
        IRS1099Adjustment: Record "IRS 1099 Adjustment";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 332661] A "Vendor 1099 Misc" report shows the amount with adjustment

        Initialize();
        // [GIVEN] Vendor ledger entries for vendor "A" with "MISC-02" code, "Posting Date" = 01.01.2022 and total amount = 100
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeMisc, LibraryRandom.RandIntInRange(100, 1000));

        // [GIVEN] Vendor ledger entry for vendor "A" with "MISC-02" code, "Posting Date" = 01.01.2022 and total amount = 150
        // BUG 384664: Adjustment with multiple vendor ledger entries
        SetupToCreateLedgerEntriesForExistingVendor(
          SecondVendorLedgerEntry, VendorLedgerEntry."Vendor No.", IRS1099CodeMisc, LibraryRandom.RandIntInRange(1000, 2000));

        // [GIVEN] Adjustment amount equals 50 for vendor "A", code "MISC-02", Year = 2023
        LibraryLocalFunctionality.CreateIRS1099Adjustment(
          IRS1099Adjustment, VendorLedgerEntry."Vendor No.", IRS1099CodeMisc,
          Date2DMY(VendorLedgerEntry."Posting Date", 3) + 1, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Adjustment amount equals 30 for vendor "A", code "MISC-02", Year = 2022
        LibraryLocalFunctionality.CreateIRS1099Adjustment(
          IRS1099Adjustment, VendorLedgerEntry."Vendor No.", IRS1099CodeMisc,
          Date2DMY(VendorLedgerEntry."Posting Date", 3), LibraryRandom.RandDec(10, 2));

        // [THEN] Run "Vendor 1099 Misc" report
        Vendor.SetRange("No.", VendorLedgerEntry."Vendor No.");
        REPORT.Run(REPORT::"Vendor 1099 Misc", true, false, Vendor);

        // [THEN] Report has amount 280
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          GetAmtMISC02, -VendorLedgerEntry.Amount - SecondVendorLedgerEntry.Amount + IRS1099Adjustment.Amount);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaShowAmountWithAdjustment()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SecondVendorLedgerEntry: Record "Vendor Ledger Entry";
        IRS1099Adjustment: Record "IRS 1099 Adjustment";
        AMagneticMediaMgt: Codeunit "A/P Magnetic Media Management";
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 332661] A "Vendor 1099 Magnetic Media" report shows the amount with adjustment
        Initialize();

        // [GIVEN] Vendor ledger entries for vendor "A" with "MISC-02" code, "Posting Date" = 01.01.2022 and total amount = 100
        // BUG 384664: Adjustment with multiple vendor ledger entries
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeMisc, LibraryRandom.RandIntInRange(5000, 10000));

        // [GIVEN] Vendor ledger entry for vendor "A" with "MISC-02" code, "Posting Date" = 01.01.2022 and total amount = 150
        // BUG 384664: Adjustment with multiple vendor ledger entries
        SetupToCreateLedgerEntriesForExistingVendor(
          SecondVendorLedgerEntry, VendorLedgerEntry."Vendor No.", IRS1099CodeMisc, LibraryRandom.RandIntInRange(1000, 2000));

        // [GIVEN] Adjustment amount equals 50 for vendor "A", code "MISC-02", Year = 2023
        LibraryLocalFunctionality.CreateIRS1099Adjustment(
          IRS1099Adjustment, VendorLedgerEntry."Vendor No.", IRS1099CodeMisc,
          Date2DMY(VendorLedgerEntry."Posting Date", 3) + 1, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Adjustment amount equals 30 for vendor "A", code "MISC-02", Year = 2022
        LibraryLocalFunctionality.CreateIRS1099Adjustment(
          IRS1099Adjustment, VendorLedgerEntry."Vendor No.", IRS1099CodeMisc,
          Date2DMY(VendorLedgerEntry."Posting Date", 3), LibraryRandom.RandDec(10, 2));

        Commit();

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReportSingleVendor(FileName, VendorLedgerEntry."Vendor No.");

        // [THEN] Line has amount element with value "00000280 00"
        Assert.AreEqual(
          AMagneticMediaMgt.FormatMoneyAmount(-VendorLedgerEntry.Amount - SecondVendorLedgerEntry.Amount + IRS1099Adjustment.Amount, 12),
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 3, 67, 12), AmountErr);

        FileManagement.DeleteServerFile(FileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Calc1099AmountFunctionFailsIfCodeNotFound()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        IRS1099Management: Codeunit "IRS 1099 Management";
        DummyCodes: array[20] of Code[10];
        InvoiceAmount: Decimal;
        Amounts: array[20] of Decimal;
        EntryAmount: Decimal;
        DummyLastLineNo: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 332661] Calculate1099Amount function of codeunit "IRS 1099 Management" failed on non-existing IRS 1099 code

        Initialize();

        // [GIVEN] Vendor Ledger Entry with IRS 1099 code "DIV-01-A"
        EntryAmount := LibraryRandom.RandIntInRange(100, 1000);
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeDiv, EntryAmount);
        // [GIVEN] Codes array does not exists the code from Vendor Ledger Entry

        // [WHEN] Call function Calculate1099Amount and pass Codes array
        asserterror IRS1099Management.Calculate1099Amount(
            InvoiceAmount, Amounts, DummyCodes, DummyLastLineNo, VendorLedgerEntry, Round(EntryAmount / LibraryRandom.RandIntInRange(3, 1)));

        // [THEN] An error message "Unknown code" shown
        Assert.ExpectedError(
          StrSubstNo(UnkownCodeErr, VendorLedgerEntry."Entry No.", VendorLedgerEntry."Vendor No.", VendorLedgerEntry."IRS 1099 Code"));
    end;

    [Test]
    [HandlerFunctions('Vendor1099NecRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099NecReportShowAmountWithAdjustment()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SecondVendorLedgerEntry: Record "Vendor Ledger Entry";
        IRS1099Adjustment: Record "IRS 1099 Adjustment";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 384664] A "Vendor 1099 Nec" report shows the amount with adjustment

        Initialize();
        // [GIVEN] Vendor ledger entry for vendor "A" with "NEC-01" code, "Posting Date" = 01.01.2022 and total amount = 1000
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeNec01Tok, LibraryRandom.RandIntInRange(1000, 2000));

        // [GIVEN] Vendor ledger entry for vendor "A" with "NEC-01" code, "Posting Date" = 01.01.2022 and total amount = 1500
        SetupToCreateLedgerEntriesForExistingVendor(
          SecondVendorLedgerEntry, VendorLedgerEntry."Vendor No.", IRS1099CodeNec01Tok, LibraryRandom.RandIntInRange(1000, 2000));

        // [GIVEN] Adjustment amount equals 50 for vendor "A", code "NEC-01", Year = 2023
        LibraryLocalFunctionality.CreateIRS1099Adjustment(
          IRS1099Adjustment, VendorLedgerEntry."Vendor No.", IRS1099CodeNec01Tok,
          Date2DMY(VendorLedgerEntry."Posting Date", 3) + 1, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Adjustment amount equals 30 for vendor "A", code "NEC-01", Year = 2022
        LibraryLocalFunctionality.CreateIRS1099Adjustment(
          IRS1099Adjustment, VendorLedgerEntry."Vendor No.", IRS1099CodeNec01Tok,
          Date2DMY(VendorLedgerEntry."Posting Date", 3), LibraryRandom.RandDec(10, 2));

        // [THEN] Run "Vendor 1099 Nec" report
        Vendor.SetRange("No.", VendorLedgerEntry."Vendor No.");
        REPORT.Run(REPORT::"Vendor 1099 Nec", true, false, Vendor);

        // [THEN] Report has amount 1030
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          GetAmtNEC01Tok, -VendorLedgerEntry.Amount - SecondVendorLedgerEntry.Amount + IRS1099Adjustment.Amount);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaNec07AmountCode()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AMagneticMediaMgt: Codeunit "A/P Magnetic Media Management";
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 380761] The magnetic media file contains the information about the NEC-01 code

        Initialize();

        // [GIVEN] Vendor entry with NEC-07 code and amount = "X"
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeNec01Tok, LibraryRandom.RandIntInRange(5000, 10000));
        Commit();

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] A record has "NE1"
        Assert.AreEqual('NE1', LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 2, 26, 3), AmountCodeErr);

        // [THEN] B record has "X"
        Assert.AreEqual(
          AMagneticMediaMgt.FormatMoneyAmount(-VendorLedgerEntry.Amount, 12),
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 3, 55, 12), AmountErr);

        // [THEN] C record has "X"
        Assert.AreEqual(
          AMagneticMediaMgt.FormatMoneyAmount(-VendorLedgerEntry.Amount, 18),
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 4, 16, 18), AmountErr);

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaOrderOfMultipleMiscCodes()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        FileName: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 380761] The magnetic media file contains the correct order of the multiple MISC codes

        Initialize();

        // [GIVEN] Vendor entries with codes "MISC-14", "MISC-09", "MISC-10", "MISC-01", "MISC-01", "MISC-05", "MISC-12"
        // Work item id 458117: Misc code "MISC-13" has been replaced with misc code "MISC-14"
        VendorNo := CreateVendor();
        SetupToCreateLedgerEntriesForExistingVendor(
          VendorLedgerEntry, VendorNo, IRS1099CodeMisc14Tok, LibraryRandom.RandIntInRange(5000, 10000));
        SetupToCreateLedgerEntriesForExistingVendor(
          VendorLedgerEntry, VendorNo, IRS1099CodeMisc09Tok, LibraryRandom.RandIntInRange(5000, 10000));
        SetupToCreateLedgerEntriesForExistingVendor(
          VendorLedgerEntry, VendorNo, IRS1099CodeMisc10Tok, LibraryRandom.RandIntInRange(5000, 10000));
        SetupToCreateLedgerEntriesForExistingVendor(
          VendorLedgerEntry, VendorNo, IRS1099CodeMisc01Tok, LibraryRandom.RandIntInRange(5000, 10000));
        SetupToCreateLedgerEntriesForExistingVendor(
          VendorLedgerEntry, VendorNo, IRS1099CodeMisc05Tok, LibraryRandom.RandIntInRange(5000, 10000));
        SetupToCreateLedgerEntriesForExistingVendor(
          VendorLedgerEntry, VendorNo, IRS1099CodeMisc12Tok, LibraryRandom.RandIntInRange(5000, 10000));
        Commit();

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] A record has "15ABCD"
        Assert.AreEqual('15ABCD', LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 2, 28, 6), AmountCodeErr);

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099InformationRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099InformationReportContainsNecCode()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 386168] Vendor 1099 information reports contains the NEC code

        Initialize();
        // [GIVEN] Vendor Ledger Entry with "NEC-01" code and Amount = "X"
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeNec01Tok, LibraryRandom.RandIntInRange(100, 1000));

        // [WHEN] Run Vendor 1099 information report
        REPORT.Run(REPORT::"Vendor 1099 Information");

        // [THEN] Vendor 1099 Information report Vendor Ledger Entry's amount "X"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Amounts, -VendorLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaMisc10CodeHasCorrectPosition()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AMagneticMediaMgt: Codeunit "A/P Magnetic Media Management";
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 389780] The magnetic media file contains the information about the MISC-10 code in the correct position in B and C sections

        Initialize();

        // [GIVEN] Vendor entry with MISC-10 code and amount = "X"
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeMisc10Tok, LibraryRandom.RandIntInRange(5000, 10000));
        Commit();

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] B record has "X" amount in position 187 to 198
        Assert.AreEqual(
          AMagneticMediaMgt.FormatMoneyAmount(-VendorLedgerEntry.Amount, 12),
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 3, 187, 12), AmountErr);

        // [THEN] C record has "X" amount in position 214 to 231
        Assert.AreEqual(
          AMagneticMediaMgt.FormatMoneyAmount(-VendorLedgerEntry.Amount, 18),
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 4, 214, 18), AmountErr);

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099Misc2020ChangeCurrYearRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ChangeYearInMiscReport()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        OldWorkDate: Date;
    begin
        // [SCENARIO 392599] Stan can change the year on the MISC report's request page to see the actual data

        // [GIVEN] Purchase invoice with MISC-02 code with Date = 01.01.2021
        Initialize();
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeMisc, LibraryRandom.RandIntInRange(100, 1000));

        // [GIVEN] Work date is "01.01.2022"
        OldWorkDate := WorkDate();
        WorkDate := CalcDate('<1Y>', WorkDate());

        // [WHEN] Run Vendor 1099 MISC Report and set year = 2021
        LibraryVariableStorage.Enqueue(Date2DMY(OldWorkDate, 3));
        REPORT.Run(REPORT::"Vendor 1099 Misc 2020");

        // [THEN] "MISC-02" value exists in the Report
        LibraryReportDataset.LoadDataSetFile();
        VendorLedgerEntry.CalcFields(Amount);
        LibraryReportDataset.AssertElementWithValueExists(GetAmtMISC02, -VendorLedgerEntry.Amount);
        LibraryVariableStorage.AssertEmpty();

        // Tear down
        Workdate := OldWorkDate;
    end;

    [Test]
    [HandlerFunctions('Vendor1099DivChangeCurrYearRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ChangeYearInDivReport()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        OldWorkDate: Date;
    begin
        // [SCENARIO 392599] Stan can change the year on the DIV report's request page to see the actual data

        // [GIVEN] Purchase invoice with DIV-01 code with Date = 01.01.2021
        Initialize();
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeDiv, LibraryRandom.RandIntInRange(100, 1000));

        // [GIVEN] Work date is "01.01.2022"
        OldWorkDate := WorkDate();
        WorkDate := CalcDate('<1Y>', WorkDate());

        // [WHEN] Run Vendor 1099 DIV Report and set year = 2021
        LibraryVariableStorage.Enqueue(Date2DMY(OldWorkDate, 3));
        REPORT.Run(REPORT::"Vendor 1099 Div");

        // [THEN] "DIV-01" value exists in the Report
        LibraryReportDataset.LoadDataSetFile();
        VendorLedgerEntry.CalcFields(Amount);
        LibraryReportDataset.AssertElementWithValueExists(GetAmtCombinedDivCodeAB, -VendorLedgerEntry.Amount);
        LibraryVariableStorage.AssertEmpty();

        // Tear down
        Workdate := OldWorkDate;
    end;

    [Test]
    [HandlerFunctions('Vendor1099IntChangeCurrYearRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ChangeYearInIntReport()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        OldWorkDate: Date;
    begin
        // [SCENARIO 392599] Stan can change the year on the INT report's request page to see the actual data

        // [GIVEN] Purchase invoice with INT-01 code with Date = 01.01.2021
        Initialize();
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeInt, LibraryRandom.RandIntInRange(100, 1000));

        // [GIVEN] Work date is "01.01.2022"
        OldWorkDate := WorkDate();
        WorkDate := CalcDate('<1Y>', WorkDate());

        // [WHEN] Run Vendor 1099 Int Report and set year = 2021
        LibraryVariableStorage.Enqueue(Date2DMY(OldWorkDate, 3));
        REPORT.Run(REPORT::"Vendor 1099 Int");

        // [THEN] "DIV-01" value exists in the Report
        LibraryReportDataset.LoadDataSetFile();
        VendorLedgerEntry.CalcFields(Amount);
        LibraryReportDataset.AssertElementWithValueExists(GetAmtINT01, -VendorLedgerEntry.Amount);
        LibraryVariableStorage.AssertEmpty();

        // Tear down
        Workdate := OldWorkDate;
    end;

    [Test]
    [HandlerFunctions('Vendor1099Misc2022DoNothingRPH,UseNewIRSFormsFeatureMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MiscReportRunsFromTheVendorCard()
    var
        VendorCardPage: TestPage "Vendor Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 395105] Stan can open the Vendor 1099 Misc 2020 report from the vendor card

        Initialize();
        VendorCardPage.OpenEdit();
        VendorCardPage.Filter.SetFilter("No.", CreateVendor());
        VendorCardPage."Vendor 1099 Misc".Invoke();
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaMisc11CodeHasCorrectPosition()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AMagneticMediaMgt: Codeunit "A/P Magnetic Media Management";
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 41241] The magnetic media file contains the information about the MISC-11 code in the correct position in B and C sections

        Initialize();

        // [GIVEN] Vendor entry with MISC-11 code and amount = "X"
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeMisc11Tok, LibraryRandom.RandIntInRange(5000, 10000));
        Commit();

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] B record has "X" amount in position 223 to 234
        Assert.AreEqual(
          AMagneticMediaMgt.FormatMoneyAmount(-VendorLedgerEntry.Amount, 12),
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 3, 223, 12), AmountErr);

        // [THEN] C record has "X" amount in position 268 to 285
        Assert.AreEqual(
          AMagneticMediaMgt.FormatMoneyAmount(-VendorLedgerEntry.Amount, 18),
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 4, 268, 18), AmountErr);

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaDiv02EAndFCodesHasCorrectPosition()
    var
        VendorLedgerEntry: array[2] of Record "Vendor Ledger Entry";
        AMagneticMediaMgt: Codeunit "A/P Magnetic Media Management";
        FileName: Text;
        VendorNo: Code[20];
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 41241] The magnetic media file contains the information about the DIV-02-E and DIV-02-F codes in the correct position in B and C sections

        Initialize();

        VendorNo := CreateVendor();
        // [GIVEN] Vendor entry with DIV-02-E code and amount = "X"
        SetupToCreateLedgerEntriesForExistingVendor(
          VendorLedgerEntry[1], VendorNo, IRS1099CodeDiv02ETok, LibraryRandom.RandIntInRange(5000, 10000));
        // [GIVEN] Vendor entry with DIV-02-F code and amount = "Y"
        SetupToCreateLedgerEntriesForExistingVendor(
          VendorLedgerEntry[2], VendorNo, IRS1099CodeDiv02FTok, LibraryRandom.RandIntInRange(5000, 10000));
        Commit();

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] B record has "X" amount in position 247 to 258
        Assert.AreEqual(
          AMagneticMediaMgt.FormatMoneyAmount(-VendorLedgerEntry[1].Amount, 12),
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 3, 247, 12), AmountErr);

        // [THEN] B record has "Y" amount in position 259 to 270
        Assert.AreEqual(
          AMagneticMediaMgt.FormatMoneyAmount(-VendorLedgerEntry[2].Amount, 12),
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 3, 259, 12), AmountErr);

        // [THEN] C record has "X" amount in position 304 to 321
        Assert.AreEqual(
          AMagneticMediaMgt.FormatMoneyAmount(-VendorLedgerEntry[1].Amount, 18),
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 4, 304, 18), AmountErr);

        // [THEN] C record has "Y" amount in position 322 to 339
        Assert.AreEqual(
          AMagneticMediaMgt.FormatMoneyAmount(-VendorLedgerEntry[2].Amount, 18),
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 4, 322, 18), AmountErr);

        FILE.Erase(FileName);
    end;


    [Test]
    [HandlerFunctions('Vendor1099Misc2021ChangeCurrYearRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ChangeYearInMisc2021Report()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        OldWorkDate: Date;
    begin
        // [SCENARIO 422833] Stan can change the year on the MISC 2021 report's request page to see the actual data

        // [GIVEN] Purchase invoice with MISC-02 code with Date = 01.01.2021
        Initialize();
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeMisc, LibraryRandom.RandIntInRange(100, 1000));

        // [GIVEN] Work date is "01.01.2022"
        OldWorkDate := WorkDate();
        WorkDate := CalcDate('<1Y>', WorkDate());

        // [WHEN] Run Vendor 1099 MISC 2021 Report and set year = 2021
        LibraryVariableStorage.Enqueue(Date2DMY(OldWorkDate, 3));
        REPORT.Run(REPORT::"Vendor 1099 Misc 2021");

        // [THEN] "MISC-02" value exists in the Report
        LibraryReportDataset.LoadDataSetFile();
        VendorLedgerEntry.CalcFields(Amount);
        LibraryReportDataset.AssertElementWithValueExists(GetAmtMISC02, -VendorLedgerEntry.Amount);
        LibraryVariableStorage.AssertEmpty();

        // Tear down
        Workdate := OldWorkDate;
    end;

    [Test]
    [HandlerFunctions('Vendor1099Div2021ChangeCurrYearRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ChangeYearInDiv2021Report()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        OldWorkDate: Date;
    begin
        // [SCENARIO 422833] Stan can change the year on the DIV 2021 report's request page to see the actual data

        // [GIVEN] Purchase invoice with DIV-01 code with Date = 01.01.2021
        Initialize();
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeDiv, LibraryRandom.RandIntInRange(100, 1000));

        // [GIVEN] Work date is "01.01.2022"
        OldWorkDate := WorkDate();
        WorkDate := CalcDate('<1Y>', WorkDate());

        // [WHEN] Run Vendor 1099 DIV 2021 Report and set year = 2021
        LibraryVariableStorage.Enqueue(Date2DMY(OldWorkDate, 3));
        REPORT.Run(REPORT::"Vendor 1099 Div 2021");

        // [THEN] "DIV-01" value exists in the Report
        LibraryReportDataset.LoadDataSetFile();
        VendorLedgerEntry.CalcFields(Amount);
        LibraryReportDataset.AssertElementWithValueExists(GetAmtCombinedDivCodeAB, -VendorLedgerEntry.Amount);
        LibraryVariableStorage.AssertEmpty();

        // Tear down
        Workdate := OldWorkDate;
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaMiscCRecLinePayeeName()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        FileName: Text;
        i: Integer;
        ExpectedResult: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 423875] Vendor 1099 Magnetic Media's C record line with code "MISC" has totals H and J on position 304
        Initialize();

        // [GIVEN] Vendor ledger entry with "IRS 1099 Code" = "MISC"
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeMisc, LibraryRandom.RandIntInRange(100, 1000));

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] C line has 36 zeroes (18 for H and 18 for J) on position 304
        for i := 1 to 36 do
            ExpectedResult += '0';
        Assert.AreEqual(
          ExpectedResult,
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 4, 304, StrLen(ExpectedResult)), '');

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaMiscBRecLinePayeeName()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 423875] Vendor 1099 Magnetic Media's B record line with code "MISC" has "Payee Name" element on position 288

        Initialize();

        // [GIVEN] Vendor ledger entry with vendor Name = "X" and "IRS 1099 Code" = "MISC"
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeMisc, LibraryRandom.RandIntInRange(100, 1000));

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] B line has "X" on position 288
        Vendor.Get(VendorLedgerEntry."Vendor No.");
        Assert.AreEqual(
          Vendor.Name,
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 3, 288, StrLen(Vendor.Name)), '');

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaDivCRecLinePayeeName()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        FileName: Text;
        i: Integer;
        ExpectedResult: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 423875] Vendor 1099 Magnetic Media's C record line with code "DIV" has totals H and J on position 304
        Initialize();

        // [GIVEN] Vendor ledger entry with "IRS 1099 Code" = "DIV"
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeDiv, LibraryRandom.RandIntInRange(100, 1000));

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] C line has 36 zeroes (18 for H and 18 for J) on position 304
        for i := 1 to 36 do
            ExpectedResult += '0';
        Assert.AreEqual(
          ExpectedResult,
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 4, 304, StrLen(ExpectedResult)), '');

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaDivBRecLinePayeeName()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 423875] Vendor 1099 Magnetic Media's B record line with code "DIV" has "Payee Name" element on position 288

        Initialize();

        // [GIVEN] Vendor ledger entry with vendor Name = "X" and "IRS 1099 Code" = "DIV"
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeDiv, LibraryRandom.RandIntInRange(100, 1000));

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] B line has "X" on position 288
        Vendor.Get(VendorLedgerEntry."Vendor No.");
        Assert.AreEqual(
          Vendor.Name,
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 3, 288, StrLen(Vendor.Name)), '');

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaIntCRecLinePayeeName()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        FileName: Text;
        i: Integer;
        ExpectedResult: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 423875] Vendor 1099 Magnetic Media's C record line with code "INT" has totals H and J on position 304
        Initialize();

        // [GIVEN] Vendor ledger entry with "IRS 1099 Code" = "INT"
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeInt, LibraryRandom.RandIntInRange(100, 1000));

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] C line has 36 zeroes (18 for H and 18 for J) on position 304
        for i := 1 to 36 do
            ExpectedResult += '0';
        Assert.AreEqual(
          ExpectedResult,
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 4, 304, StrLen(ExpectedResult)), '');

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaIntBRecLinePayeeName()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 423875] Vendor 1099 Magnetic Media's B record line with code "INT" has "Payee Name" element on position 288

        Initialize();

        // [GIVEN] Vendor ledger entry with vendor Name = "X" and "IRS 1099 Code" = "INT"
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeInt, LibraryRandom.RandIntInRange(100, 1000));

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] B line has "X" on position 288
        Vendor.Get(VendorLedgerEntry."Vendor No.");
        Assert.AreEqual(
          Vendor.Name,
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 3, 288, StrLen(Vendor.Name)), '');

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaNecCRecLinePayeeName()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        FileName: Text;
        i: Integer;
        ExpectedResult: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 423875] Vendor 1099 Magnetic Media's C record line with code "NEC" has totals H and J on position 304
        Initialize();

        // [GIVEN] Vendor ledger entry with "IRS 1099 Code" = "NEC"
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeNec01Tok, LibraryRandom.RandIntInRange(1000, 10000));

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] C line has 36 zeroes (18 for H and 18 for J) on position 304
        for i := 1 to 36 do
            ExpectedResult += '0';
        Assert.AreEqual(
          ExpectedResult,
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 4, 304, StrLen(ExpectedResult)), '');

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaNecBRecLinePayeeName()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 423875] Vendor 1099 Magnetic Media's B record line with code "NEC" has "Payee Name" element on position 288

        Initialize();

        // [GIVEN] Vendor ledger entry with vendor Name = "X" and "IRS 1099 Code" = "NEC"
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeNec01Tok, LibraryRandom.RandIntInRange(1000, 10000));

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] B line has "X" on position 288
        Vendor.Get(VendorLedgerEntry."Vendor No.");
        Assert.AreEqual(
          Vendor.Name,
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 3, 288, StrLen(Vendor.Name)), '');

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099Div2022RPH,UseNewIRSFormsFeatureMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintVendor1099Div2022()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 456917] Stan can print "Vendor 1099 Div 2022" report

        // [GIVEN] Vendor Leger Entry with "DIV-13" code and Amount = 100
        Initialize();
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeDiv13Tok, LibraryRandom.RandIntInRange(1000, 2000));

        // [WHEN] Run "Vendor 1099 Div 2022" report
        REPORT.Run(REPORT::"Vendor 1099 Div 2022");

        // [THEN] "DIV-13" code prints with amount equals 100
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtDIV13Tok, -VendorLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('Vendor1099Int2022RPH,UseNewIRSFormsFeatureMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintVendor1099Int2022()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 456917] Stan can print "Vendor 1099 Int 2022" report

        // [GIVEN] Vendor Leger Entry with "INT-01" code and Amount = 100
        Initialize();
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeInt, LibraryRandom.RandIntInRange(1000, 2000));

        // [WHEN] Run "Vendor 1099 Int 2022" report
        REPORT.Run(REPORT::"Vendor 1099 Int 2022");

        // [THEN] "INT-01" code prints with amount equals 100
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtINT01, -VendorLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('Vendor1099Misc2022RPH,UseNewIRSFormsFeatureMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintVendor1099Misc2022()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 456917] Stan can print "Vendor 1099 Misc 2022" report

        // [GIVEN] Vendor Leger Entry with "MISC-02" code and Amount = 100
        Initialize();
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeMisc, LibraryRandom.RandIntInRange(1000, 2000));

        // [WHEN] Run "Vendor 1099 Misc 2022" report
        REPORT.Run(REPORT::"Vendor 1099 Misc 2022");

        // [THEN] "MISC-02" code prints with amount equals 100
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtMISC02, -VendorLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('Vendor1099Nec2022RPH,UseNewIRSFormsFeatureMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintVendor1099Nec2022()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 456917] Stan can print "Vendor 1099 Nec 2022" report

        // [GIVEN] Vendor Leger Entry with "NEC-01" code and Amount = 100
        Initialize();
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeNec01Tok, LibraryRandom.RandIntInRange(1000, 2000));

        // [WHEN] Run "Vendor 1099 Misc 2022" report
        REPORT.Run(REPORT::"Vendor 1099 Nec 2022");

        // [THEN] "NEC-01" code prints with amount equals 100
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtNEC01Tok, -VendorLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaMisc14CodeHasCorrectPosition()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AMagneticMediaMgt: Codeunit "A/P Magnetic Media Management";
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 458117] The magnetic media file contains the information about the MISC-14 code in the correct position in B and C sections

        Initialize();

        // [GIVEN] Vendor entry with MISC-14 code and amount = "X"
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeMisc14Tok, LibraryRandom.RandIntInRange(5000, 10000));
        Commit();

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] B record has "X" amount in position 175 to 186
        Assert.AreEqual(
          AMagneticMediaMgt.FormatMoneyAmount(-VendorLedgerEntry.Amount, 12),
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 3, 175, 12), AmountErr);

        // [THEN] C record has "X" amount in position 196 to 213
        Assert.AreEqual(
          AMagneticMediaMgt.FormatMoneyAmount(-VendorLedgerEntry.Amount, 18),
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 4, 196, 18), AmountErr);

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaDiv12CodeHasCorrectPosition()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AMagneticMediaMgt: Codeunit "A/P Magnetic Media Management";
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 458117] The magnetic media file contains the information about the DIV-12 code in the correct position in B and C sections

        Initialize();

        // [GIVEN] Vendor entry with DIV-12 code and amount = "X"
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeDiv12Tok, LibraryRandom.RandIntInRange(5000, 10000));
        Commit();

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] B record has "X" amount in position 223 to 234
        Assert.AreEqual(
          AMagneticMediaMgt.FormatMoneyAmount(-VendorLedgerEntry.Amount, 12),
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 3, 223, 12), AmountErr);

        // [THEN] C record has "X" amount in position 268 to 285
        Assert.AreEqual(
          AMagneticMediaMgt.FormatMoneyAmount(-VendorLedgerEntry.Amount, 18),
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 4, 268, 18), AmountErr);

        FILE.Erase(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaDiv13CodeHasCorrectPosition()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AMagneticMediaMgt: Codeunit "A/P Magnetic Media Management";
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 458117] The magnetic media file contains the information about the DIV-13 code in the correct position in B and C sections

        Initialize();

        // [GIVEN] Vendor entry with DIV-13 code and amount = "X"
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeDiv13Tok, LibraryRandom.RandIntInRange(5000, 10000));
        Commit();

        // [WHEN] Run Vendor 1099 Magnetic Media report
        RunVendor1099MagneticMediaReport(FileName);

        // [THEN] B record has "X" amount in position 235 to 246
        Assert.AreEqual(
          AMagneticMediaMgt.FormatMoneyAmount(-VendorLedgerEntry.Amount, 12),
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 3, 235, 12), AmountErr);

        // [THEN] C record has "X" amount in position 286 to 303
        Assert.AreEqual(
          AMagneticMediaMgt.FormatMoneyAmount(-VendorLedgerEntry.Amount, 18),
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 4, 286, 18), AmountErr);

        FILE.Erase(FileName);
    end;


    [Test]
    [HandlerFunctions('Vendor1099Nec2022ChangeCurrYearRPH,UseNewIRSFormsFeatureMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ChangeYearInNec2022Report()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        OldWorkDate: Date;
    begin
        // [SCENARIO 461396] Stan can change the year on the MISC 2021 report's request page to see the actual data

        // [GIVEN] Purchase invoice with NEC-01 code with Date = 01.01.2021
        Initialize();
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeNec01Tok, LibraryRandom.RandIntInRange(1000, 5000));

        // [GIVEN] Work date is "01.01.2022"
        OldWorkDate := WorkDate();
        WorkDate := CalcDate('<1Y>', WorkDate());

        // [WHEN] Run Vendor 1099 Nec 2022 Report and set year = 2021
        LibraryVariableStorage.Enqueue(Date2DMY(OldWorkDate, 3));
        REPORT.Run(REPORT::"Vendor 1099 Nec 2022");

        // [THEN] "NEC-01" value exists in the Report
        LibraryReportDataset.LoadDataSetFile();
        VendorLedgerEntry.CalcFields(Amount);
        LibraryReportDataset.AssertElementWithValueExists(GetAmtNEC01Tok, -VendorLedgerEntry.Amount);
        LibraryVariableStorage.AssertEmpty();

        // Tear down
        Workdate := OldWorkDate;
    end;

    [Test]
    [HandlerFunctions('Vendor1099Div2022TestPrintRPH,UseNewIRSFormsFeatureMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099Div2022WithTestPrintOption()
    begin
        // [SCENARIO 460207] Stan can print "Vendor 1099 Div 2022" report with a "Test Print" option

        Initialize();
        LibraryVariableStorage.Enqueue(CreateVendor());

        // [WHEN] Run "Vendor 1099 Div 2022" report with "Test Print" option enabled
        REPORT.Run(REPORT::"Vendor 1099 Div 2022");

        // [THEN] "DIV-03" code prints with amount equals test amount of 9999999.99
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtDIV03Tok, 9999999.99);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('Vendor1099Div2021TestPrintRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099Div2021WithTestPrintOption()
    begin
        // [SCENARIO 460207] Stan can print "Vendor 1099 Div 2021" report with a "Test Print" option

        Initialize();
        LibraryVariableStorage.Enqueue(CreateVendor());

        // [WHEN] Run "Vendor 1099 Div 2021" report with "Test Print" option enabled
        REPORT.Run(REPORT::"Vendor 1099 Div 2021");

        // [THEN] "DIV-03" code prints with amount equals test amount of 9999999.99
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtDIV03Tok, 9999999.99);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH_Foreign')]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMedia_ForeignEntity()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 491564] A "Vendor 1099 Magnetic Media" report has Foreign Entity indicator in position 740 for foreign vendors
        Initialize();

        // [GIVEN] Vendor ledger entries for vendor "A" with "MISC-02" code
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeMisc, LibraryRandom.RandIntInRange(5000, 10000));

        Commit();

        // [WHEN] Run Vendor 1099 Magnetic Media report with foreign vendor info on request page
        RunVendor1099MagneticMediaReportSingleVendor(FileName, VendorLedgerEntry."Vendor No.");

        // [THEN] Foreign Vendor indicator is '1' in position 740
        Assert.AreEqual('1', LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 1, 740, 1), 'Foreign Vendor indicator is not "1"');

        FileManagement.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('Vendor1099Div2022RPH,UseNewIRSFormsFeatureMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099DivReportShowAmountOnlyAdjustment()
    var
        IRS1099Adjustment: Record "IRS 1099 Adjustment";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 497306] A "Vendor 1099 Div 2022" report shows the amount only from adjustment when no vendor ledger entries exist for the vendor

        Initialize();

        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Adjustment amount equals 100 for vendor, IRS code "DIV-01", Year = 2022
        LibraryLocalFunctionality.CreateIRS1099Adjustment(
          IRS1099Adjustment, Vendor."No.", IRS1099CodeDiv, Date2DMY(WorkDate(), 3), LibraryRandom.RandDecInDecimalRange(1000, 2000, 2));

        // [THEN] Run "Vendor 1099 Div 2022" report
        LibraryVariableStorage.Enqueue(Vendor."No.");
        REPORT.Run(REPORT::"Vendor 1099 Div 2022", true, false);

        // [THEN] Report has amount 100
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtCombinedDivCodeAB, IRS1099Adjustment.Amount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('Vendor1099Misc2022RPH,UseNewIRSFormsFeatureMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099MiscReportShowAmountOnlyAdjustment()
    var
        IRS1099Adjustment: Record "IRS 1099 Adjustment";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 497306] A "Vendor 1099 Misc 2022" report shows the amount only from adjustment when no vendor ledger entries exist for the vendor

        Initialize();

        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Adjustment amount equals 100 for vendor, IRS code "MISC-02", Year = 2022
        LibraryLocalFunctionality.CreateIRS1099Adjustment(
          IRS1099Adjustment, Vendor."No.", IRS1099CodeMisc, Date2DMY(WorkDate(), 3), LibraryRandom.RandDecInDecimalRange(1000, 2000, 2));

        // [THEN] Run "Vendor 1099 Div 2022" report
        LibraryVariableStorage.Enqueue(Vendor."No.");
        REPORT.Run(REPORT::"Vendor 1099 Misc 2022", true, false);

        // [THEN] Report has amount 100
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtMISC02, IRS1099Adjustment.Amount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('Vendor1099Nec2022RPH,UseNewIRSFormsFeatureMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099NecReportShowAmountOnlyAdjustment()
    var
        IRS1099Adjustment: Record "IRS 1099 Adjustment";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 497306] A "Vendor 1099 Nec 2022" report shows the amount only from adjustment when no vendor ledger entries exist for the vendor

        Initialize();

        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Adjustment amount equals 100 for vendor, IRS code "Nec-01", Year = 2022
        LibraryLocalFunctionality.CreateIRS1099Adjustment(
          IRS1099Adjustment, Vendor."No.", IRS1099CodeNec01Tok, Date2DMY(WorkDate(), 3), LibraryRandom.RandDecInDecimalRange(1000, 2000, 2));

        // [THEN] Run "Vendor 1099 Nec 2022" report
        LibraryVariableStorage.Enqueue(Vendor."No.");
        REPORT.Run(REPORT::"Vendor 1099 Nec 2022", true, false);

        // [THEN] Report has amount 100
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtNEC01Tok, IRS1099Adjustment.Amount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('Vendor1099Int2022RPH,UseNewIRSFormsFeatureMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099IntReportShowAmountOnlyAdjustment()
    var
        IRS1099Adjustment: Record "IRS 1099 Adjustment";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 497306] A "Vendor 1099 Int 2022" report shows the amount only from adjustment when no vendor ledger entries exist for the vendor

        Initialize();

        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Adjustment amount equals 100 for vendor, IRS code "Int-01", Year = 2022
        LibraryLocalFunctionality.CreateIRS1099Adjustment(
          IRS1099Adjustment, Vendor."No.", IRS1099CodeInt, Date2DMY(WorkDate(), 3), LibraryRandom.RandDecInDecimalRange(1000, 2000, 2));

        // [THEN] Run "Vendor 1099 Int 2022" report
        LibraryVariableStorage.Enqueue(Vendor."No.");
        REPORT.Run(REPORT::"Vendor 1099 Int 2022", true, false);

        // [THEN] Report has amount 100
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtINT01, IRS1099Adjustment.Amount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('Vendor1099Misc2022RPH,UseNewIRSFormsFeatureMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099Misc2022Refund()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        InvoiceAmount: Decimal;
        CrMemoAmount: Decimal;
    begin
        // [SCENARIO 497410] Stan can print "Vendor 1099 Misc 2022" report that consideres refunds

        Initialize();
        InvoiceAmount := LibraryRandom.RandIntInRange(1000, 2000);
        // [GIVEN] Invoice Vendor Leger Entry with "MISC-02" code and Amount = 100
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeMisc, InvoiceAmount);
        VendorNo := VendorLedgerEntry."Vendor No.";
        // [GIVEN] Credit Memo Vendor Leger Entry with "MISC-02" code and Amount = -20
        CrMemoAmount := Round(InvoiceAmount / 2);
        Clear(VendorLedgerEntry);
        CreateNegativeLedgerEntriesForVendor(VendorLedgerEntry, VendorNo, IRS1099CodeMisc, -CrMemoAmount);

        // [WHEN] Run "Vendor 1099 Misc 2022" report
        REPORT.Run(REPORT::"Vendor 1099 Misc 2022");

        // [THEN] "MISC-02" code prints with amount equals 80
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtMISC02, InvoiceAmount - CrMemoAmount);
    end;

    [Test]
    [HandlerFunctions('Vendor1099Div2022RPH,UseNewIRSFormsFeatureMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099Div2022Refund()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        InvoiceAmount: Decimal;
        CrMemoAmount: Decimal;
    begin
        // [SCENARIO 497410] Stan can print "Vendor 1099 Div 2022" report that consideres refunds

        Initialize();
        InvoiceAmount := LibraryRandom.RandIntInRange(1000, 2000);
        // [GIVEN] Invoice Vendor Leger Entry with "DIV-01" code and Amount = 100
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeDiv, InvoiceAmount);
        VendorNo := VendorLedgerEntry."Vendor No.";
        // [GIVEN] Credit Memo Vendor Leger Entry with "DIV-01" code and Amount = -20
        CrMemoAmount := Round(InvoiceAmount / 2);
        Clear(VendorLedgerEntry);
        CreateNegativeLedgerEntriesForVendor(VendorLedgerEntry, VendorNo, IRS1099CodeDiv, -CrMemoAmount);

        // [WHEN] Run "Vendor 1099 Div 2022" report
        REPORT.Run(REPORT::"Vendor 1099 Div 2022");

        // [THEN] "DIV-01" code prints with amount equals 80
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtCombinedDivCodeAB, InvoiceAmount - CrMemoAmount);
    end;

    [Test]
    [HandlerFunctions('Vendor1099Nec2022RPH,UseNewIRSFormsFeatureMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099Nec2022Refund()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        InvoiceAmount: Decimal;
        CrMemoAmount: Decimal;
    begin
        // [SCENARIO 497410] Stan can print "Vendor 1099 Nec 2022" report that consideres refunds

        Initialize();
        InvoiceAmount := LibraryRandom.RandIntInRange(1000, 2000);
        // [GIVEN] Invoice Vendor Leger Entry with "NEC-01" code and Amount = 100
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeNec01Tok, InvoiceAmount);
        VendorNo := VendorLedgerEntry."Vendor No.";
        // [GIVEN] Credit Memo Vendor Leger Entry with "NEC-01" code and Amount = -20
        CrMemoAmount := Round(InvoiceAmount / 2);
        Clear(VendorLedgerEntry);
        CreateNegativeLedgerEntriesForVendor(VendorLedgerEntry, VendorNo, IRS1099CodeNec01Tok, -CrMemoAmount);

        // [WHEN] Run "Vendor 1099 Nec 2022" report
        REPORT.Run(REPORT::"Vendor 1099 Nec 2022");

        // [THEN] "NEC-01" code prints with amount equals 80
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtNEC01Tok, InvoiceAmount - CrMemoAmount);
    end;

    [Test]
    [HandlerFunctions('Vendor1099Int2022RPH,UseNewIRSFormsFeatureMessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099Int2022Refund()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        InvoiceAmount: Decimal;
        CrMemoAmount: Decimal;
    begin
        // [SCENARIO 497410] Stan can print "Vendor 1099 Int 2022" report that consideres refunds

        Initialize();
        InvoiceAmount := LibraryRandom.RandIntInRange(1000, 2000);
        // [GIVEN] Invoice Vendor Leger Entry with "INT-01" code and Amount = 100
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeInt, InvoiceAmount);
        VendorNo := VendorLedgerEntry."Vendor No.";
        // [GIVEN] Credit Memo Vendor Leger Entry with "INT-01" code and Amount = -20
        CrMemoAmount := Round(InvoiceAmount / 2);
        Clear(VendorLedgerEntry);
        CreateNegativeLedgerEntriesForVendor(VendorLedgerEntry, VendorNo, IRS1099CodeInt, -CrMemoAmount);

        // [WHEN] Run "Vendor 1099 Int 2022" report
        REPORT.Run(REPORT::"Vendor 1099 Int 2022");

        // [THEN] "INT-01" code prints with amount equals 80
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtINT01, InvoiceAmount - CrMemoAmount);
    end;

    [Test]
    [HandlerFunctions('Vendor1099InformationRPH')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure Vendor1099InformationRefund()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        InvoiceAmount: Decimal;
        CrMemoAmount: Decimal;
    begin
        // [SCENARIO 497410] Stan can print "Vendor 1099 Information" report that consideres refunds

        Initialize();
        InvoiceAmount := LibraryRandom.RandIntInRange(1000, 2000);
        // [GIVEN] Invoice Vendor Leger Entry with "INT-01" code and Amount = 100
        SetupToCreateLedgerEntriesForVendor(VendorLedgerEntry, IRS1099CodeInt, InvoiceAmount);
        VendorNo := VendorLedgerEntry."Vendor No.";
        // [GIVEN] Credit Memo Vendor Leger Entry with "INT-01" code and Amount = -20
        CrMemoAmount := Round(InvoiceAmount / 2);
        Clear(VendorLedgerEntry);
        CreateNegativeLedgerEntriesForVendor(VendorLedgerEntry, VendorNo, IRS1099CodeInt, -CrMemoAmount);

        // [WHEN] Run "Vendor 1099 Information" report
        REPORT.Run(REPORT::"Vendor 1099 Information");

        // [THEN] Report prints value 80
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Amounts, InvoiceAmount - CrMemoAmount);
    end;

    [Test]
    [HandlerFunctions('Vendor1099Misc2022RPH,UseNewIRSFormsFeatureMessageHandler')]
    procedure Vendor1099Misc2022PaymentAppliedToMultipleInvoicesEachWithPaymentDiscount()
    var
        InvVendorLedgerEntry: array[2] of Record "Vendor Ledger Entry";
        PmtVendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendorNo: Code[20];
        IRS1099Code: Code[10];
        InvAmount: array[2] of Decimal;
        PmtDiscAmount: Decimal;
        i: Integer;
    begin
        // [SCENARIO 498316] Stan can print "Vendor 1099 Misc 2022" report that considers payment discount correctly for multiple invoices applied to one payment

        Initialize();
        VendorNo := CreateVendor();
        IRS1099Code := IRS1099CodeMisc;
        // [GIVEN] Two posted invoices with "MISC-02" code and total amount = 1000
        for i := 1 to ArrayLen(InvAmount) do begin
            InvAmount[i] := LibraryRandom.RandIntInRange(1000, 2000);
            CreateVendorLedgerEntry(
                InvVendorLedgerEntry[i], InvVendorLedgerEntry[i]."Document Type"::Invoice, VendorNo, IRS1099Code, InvAmount[i]);
            CreateDetailedVendorLedgerEntry(
                InvVendorLedgerEntry[i]."Entry No.", 0, DetailedVendorLedgEntry."Entry Type"::"Initial Entry",
                InvVendorLedgerEntry[i]."Vendor No.", -InvAmount[i], true);
        end;
        // [GIVEN] A single payment applied to both invoices with payment discount = 100
        CreateVendorLedgerEntry(
          PmtVendorLedgerEntry, PmtVendorLedgerEntry."Document Type"::Payment, VendorNo, IRS1099Code, 0);  // Using 0 for zero amount.
        PmtVendorLedgerEntry."Closed by Entry No." := InvVendorLedgerEntry[2]."Entry No.";
        PmtVendorLedgerEntry.Modify();
        CreateDetailedVendorLedgerEntry(
          PmtVendorLedgerEntry."Entry No.", 0, DetailedVendorLedgEntry."Entry Type"::"Initial Entry",
          VendorNo, InvAmount[1] + InvAmount[2], true);
        PmtDiscAmount := Round(InvAmount[1] / 3);
        CreateDetailedVendorLedgerEntry(
          PmtVendorLedgerEntry."Entry No.", 0, DetailedVendorLedgEntry."Entry Type"::"Payment Discount",
          VendorNo, PmtDiscAmount, true);
        for i := 1 to ArrayLen(InvAmount) do begin
            InvVendorLedgerEntry[i]."Closed by Entry No." := PmtVendorLedgerEntry."Entry No.";
            InvVendorLedgerEntry[i].Modify();
            CreateDetailedVendorLedgerEntry(
                InvVendorLedgerEntry[i]."Entry No.", InvVendorLedgerEntry[i]."Entry No.", DetailedVendorLedgEntry."Entry Type"::Application,
                VendorNo, InvAmount[i], false);
            CreateDetailedVendorLedgerEntry(
                PmtVendorLedgerEntry."Entry No.", InvVendorLedgerEntry[i]."Entry No.", DetailedVendorLedgEntry."Entry Type"::Application,
                VendorNo, -InvAmount[i], false);
        end;
        Commit();
        LibraryVariableStorage.Enqueue(VendorNo);

        // [WHEN] Run "Vendor 1099 Misc 2022" report
        REPORT.Run(REPORT::"Vendor 1099 Misc 2022");

        // [THEN] "MISC-02" code prints with amount equals 900
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GetAmtMISC02, InvAmount[1] + InvAmount[2] - PmtDiscAmount);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('Vendor1099MagneticMediaRPH')]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaShowAmountWithOnlyAdjustment()
    var
        IRS1099Adjustment: Record "IRS 1099 Adjustment";
        AMagneticMediaMgt: Codeunit "A/P Magnetic Media Management";
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        // [FEATURE] [Vendor 1099 Magnetic Media]
        // [SCENARIO 565085] A "Vendor 1099 Magnetic Media" report shows the amount with only the adjustment
        Initialize();

        // [GIVEN] Adjustment amount equals 100 for vendor "A", code "MISC-01", Year = 2025
        LibraryLocalFunctionality.CreateIRS1099Adjustment(
          IRS1099Adjustment, LibraryPurchase.CreateVendorNo(), IRS1099CodeMisc,
          Date2DMY(WorkDate(), 3), LibraryRandom.RandDecInRange(10, 100, 2));

        Commit();
        LibraryVariableStorage.Enqueue(IRS1099Adjustment."Vendor No.");

        // [WHEN] Run Vendor 1099 Magnetic Media report for 2025 and vendor "A"
        RunVendor1099MagneticMediaReportSingleVendor(FileName, IRS1099Adjustment."Vendor No.");

        // [THEN] Line has amount element with value "00000100 00"
        Assert.AreEqual(
          AMagneticMediaMgt.FormatMoneyAmount(IRS1099Adjustment.Amount, 12),
          LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 3, 67, 12), AmountErr);

        LibraryVariableStorage.AssertEmpty();

        FileManagement.DeleteServerFile(FileName);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateDetailedVendorLedgerEntry(VendorLedgerEntryNo: Integer; AppliedVendLedgerEntryNo: Integer; EntryType: Enum "Detailed CV Ledger Entry Type"; VendorNo: Code[20]; Amount: Decimal; LedgerEntryAmount: Boolean)
    begin
        InsertDetailedVendorLedgerEntry(
          VendorLedgerEntryNo, AppliedVendLedgerEntryNo, EntryType, VendorNo, 0, Amount, LedgerEntryAmount);
    end;

    local procedure InsertDetailedVendorLedgerEntry(VendorLedgerEntryNo: Integer; AppliedVendLedgerEntryNo: Integer; EntryType: Enum "Detailed CV Ledger Entry Type"; VendorNo: Code[20]; TransactionNo: Integer; NewAmount: Decimal; LedgerEntryAmount: Boolean)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(DetailedVendorLedgEntry);
        DetailedVendorLedgEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, DetailedVendorLedgEntry.FieldNo("Entry No."));
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntryNo;
        DetailedVendorLedgEntry."Ledger Entry Amount" := LedgerEntryAmount;
        DetailedVendorLedgEntry."Applied Vend. Ledger Entry No." := AppliedVendLedgerEntryNo;
        DetailedVendorLedgEntry."Entry Type" := EntryType;
        DetailedVendorLedgEntry."Vendor No." := VendorNo;
        DetailedVendorLedgEntry.Amount := NewAmount;
        DetailedVendorLedgEntry."Amount (LCY)" := NewAmount;
        DetailedVendorLedgEntry."Transaction No." := TransactionNo;
        DetailedVendorLedgEntry.Insert();
    end;

    local procedure CalcSumOfDocs(DocAmount: array[2, 3] of Decimal; VendorIndex: Integer) Result: Decimal
    var
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(DocAmount, 2) do
            Result += DocAmount[VendorIndex, Index];

        exit(Result);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor."Federal ID No." := LibraryUTUtility.GetNewCode10();
        Vendor.Name := LibraryUtility.GenerateGUID();
        Vendor.Address := LibraryUTUtility.GetNewCode10();
        Vendor."Address 2" := LibraryUTUtility.GetNewCode10();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; IRS1099Code: Code[10]; IRSAmount: Decimal)
    begin
        InsertVendorLedgerEntry(VendorLedgerEntry, DocumentType, LibraryUTUtility.GetNewCode10(), VendorNo, 0, IRS1099Code, IRSAmount);
    end;

    local procedure InsertVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; VendorNo: Code[20]; TransactionNo: Integer; IRS1099Code: Code[10]; DocAmount: Decimal)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(VendorLedgerEntry);
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Document No." := DocumentNo;
        VendorLedgerEntry."Document Type" := DocumentType;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry."Transaction No." := TransactionNo;
        VendorLedgerEntry."IRS 1099 Code" := IRS1099Code;
        VendorLedgerEntry."IRS 1099 Amount" := -DocAmount;

        VendorLedgerEntry.Insert();
    end;

    local procedure SetupToCreateLedgerEntriesForVendor(var VendorLedgerEntry: Record "Vendor Ledger Entry"; IRS1099Code: Code[10]; VendorLedgerEntryAmount: Decimal)
    begin
        SetupToCreateLedgerEntriesForExistingVendor(VendorLedgerEntry, CreateVendor(), IRS1099Code, VendorLedgerEntryAmount);
    end;

    local procedure SetupToCreateLedgerEntriesForExistingVendor(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; IRS1099Code: Code[10]; VendorLedgerEntryAmount: Decimal)
    begin
        MockPairOfVendorLedgerEnties(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, VendorLedgerEntry."Document Type"::Payment, VendorNo, IRS1099Code, VendorLedgerEntryAmount);
    end;

    local procedure CreateNegativeLedgerEntriesForVendor(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; IRS1099Code: Code[10]; VendorLedgerEntryAmount: Decimal)
    begin
        MockPairOfVendorLedgerEnties(VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", VendorLedgerEntry."Document Type"::Refund, VendorNo, IRS1099Code, VendorLedgerEntryAmount);
    end;

    local procedure MockPairOfVendorLedgerEnties(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType1: Enum "Gen. Journal Document Type"; DocType2: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; IRS1099Code: Code[10]; VendorLedgerEntryAmount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        CreateVendorLedgerEntry(
          VendorLedgerEntry, DocType1, VendorNo, IRS1099Code, VendorLedgerEntryAmount);
        CreateVendorLedgerEntry(
          VendorLedgerEntry2, DocType2, VendorLedgerEntry."Vendor No.", IRS1099Code, 0);  // Using 0 for zero amount.
        CreateDetailedVendorLedgerEntry(
          VendorLedgerEntry."Entry No.", 0, DetailedVendorLedgEntry."Entry Type"::"Initial Entry",
          VendorLedgerEntry."Vendor No.", -VendorLedgerEntryAmount, true);
        CreateDetailedVendorLedgerEntry(
          VendorLedgerEntry2."Entry No.", 0, DetailedVendorLedgEntry."Entry Type"::"Initial Entry",
          VendorLedgerEntry."Vendor No.", VendorLedgerEntryAmount, true);
        CreateDetailedVendorLedgerEntry(
          VendorLedgerEntry."Entry No.", VendorLedgerEntry."Entry No.", DetailedVendorLedgEntry."Entry Type"::Application,
          VendorLedgerEntry."Vendor No.", VendorLedgerEntryAmount, false);
        CreateDetailedVendorLedgerEntry(
          VendorLedgerEntry2."Entry No.", VendorLedgerEntry."Entry No.", DetailedVendorLedgEntry."Entry Type"::Application,
          VendorLedgerEntry."Vendor No.", -VendorLedgerEntryAmount, false);
        VendorLedgerEntry.CalcFields(Amount);
        LibraryVariableStorage.Enqueue(VendorLedgerEntry."Vendor No.");
    end;

    local procedure SetupMultipleDocScenario(IRS1099Code: Code[10]): Decimal
    var
        VendorLedgerEntryInvoice: array[2, 3] of Record "Vendor Ledger Entry";
        VendorLedgerEntryPayment: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendorNo: array[2] of Code[20];
        TransactionNo: Integer;
        Index: Integer;
        DocAmount: array[2, 3] of Decimal;
        VendorIndex: Integer;
        VendorCount: Integer;
    begin
        // Create 2 vendors.
        // Create 3 invoices for each vendor in differenet transactions
        // Create payment and apply it for all invoices in a single transaction for both vendors

        TransactionNo := LibraryUtility.GetLastTransactionNo();

        VendorCount := ArrayLen(VendorNo);

        for VendorIndex := 1 to VendorCount do begin
            VendorNo[VendorIndex] := CreateVendor();
            for Index := 1 to ArrayLen(VendorLedgerEntryInvoice, 2) do begin
                TransactionNo += 1;
                DocAmount[VendorIndex, Index] := LibraryRandom.RandInt(100);
                InsertVendorLedgerEntry(
                  VendorLedgerEntryInvoice[VendorIndex, Index], VendorLedgerEntryInvoice[VendorIndex, Index]."Document Type"::Invoice,
                  LibraryUtility.GenerateGUID(), VendorNo[VendorIndex], TransactionNo, IRS1099Code, DocAmount[VendorIndex, Index]);
                InsertDetailedVendorLedgerEntry(
                  VendorLedgerEntryInvoice[VendorIndex, Index]."Entry No.", 0, DetailedVendorLedgEntry."Entry Type"::"Initial Entry",
                  VendorLedgerEntryInvoice[VendorIndex, Index]."Vendor No.", TransactionNo, -DocAmount[VendorIndex, Index], true);
            end;
            LibraryVariableStorage.Enqueue(VendorNo[VendorIndex]);
        end;

        TransactionNo += 1;
        for VendorIndex := 1 to VendorCount do begin
            InsertVendorLedgerEntry(
              VendorLedgerEntryPayment, VendorLedgerEntryPayment."Document Type"::Payment,
              LibraryUtility.GenerateGUID(), VendorNo[VendorIndex], TransactionNo, IRS1099Code, 0);

            for Index := 1 to ArrayLen(VendorLedgerEntryInvoice, 2) do begin
                InsertDetailedVendorLedgerEntry(
                  VendorLedgerEntryPayment."Entry No.", 0, DetailedVendorLedgEntry."Entry Type"::"Initial Entry",
                  VendorLedgerEntryPayment."Vendor No.", TransactionNo, DocAmount[VendorIndex, Index], true);
                InsertDetailedVendorLedgerEntry(
                  VendorLedgerEntryInvoice[VendorIndex, Index]."Entry No.", VendorLedgerEntryPayment."Entry No.",
                  DetailedVendorLedgEntry."Entry Type"::Application,
                  VendorLedgerEntryInvoice[VendorIndex, Index]."Vendor No.", TransactionNo, DocAmount[VendorIndex, Index], false);
                InsertDetailedVendorLedgerEntry(
                  VendorLedgerEntryPayment."Entry No.", VendorLedgerEntryInvoice[VendorIndex, Index]."Entry No.",
                  DetailedVendorLedgEntry."Entry Type"::Application,
                  VendorLedgerEntryPayment."Vendor No.", TransactionNo, -DocAmount[VendorIndex, Index], false);
            end;
        end;

        exit(CalcSumOfDocs(DocAmount, 1));
    end;

    local procedure RunVendor1099MagneticMediaReport(var FileName: Text)
    var
        Vendor1099MagneticMedia: Report "Vendor 1099 Magnetic Media";
        FileMgt: Codeunit "File Management";
    begin
        FileName := FileMgt.ServerTempFileName('txt');
        Vendor1099MagneticMedia.InitializeRequest(FileName);
        Vendor1099MagneticMedia.Run();
    end;

    local procedure RunVendor1099MagneticMediaReportSingleVendor(var FileName: Text; VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        Vendor1099MagneticMedia: Report "Vendor 1099 Magnetic Media";
        FileMgt: Codeunit "File Management";
    begin
        FileName := FileMgt.ServerTempFileName('txt');
        Vendor.SetRange("No.", VendorNo);
        Vendor1099MagneticMedia.SetTableView(Vendor);
        Vendor1099MagneticMedia.InitializeRequest(FileName);
        Vendor1099MagneticMedia.Run();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099DivRPH(var Vendor1099Div: TestRequestPage "Vendor 1099 Div")
    begin
        Vendor1099Div.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Vendor1099Div.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099DivChangeCurrYearRPH(var Vendor1099Div: TestRequestPage "Vendor 1099 Div")
    begin
        Vendor1099Div.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Vendor1099Div.Year.SetValue(LibraryVariableStorage.DequeueText());
        Vendor1099Div.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099Div2021ChangeCurrYearRPH(var Vendor1099Div2021: TestRequestPage "Vendor 1099 Div 2021")
    begin
        Vendor1099Div2021.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Vendor1099Div2021.Year.SetValue(LibraryVariableStorage.DequeueText());
        Vendor1099Div2021.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099InformationRPH(var Vendor1099Information: TestRequestPage "Vendor 1099 Information")
    begin
        Vendor1099Information.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Vendor1099Information.Vendor.SetFilter("Date Filter", Format(WorkDate()));
        Vendor1099Information.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099IntRPH(var Vendor1099Int: TestRequestPage "Vendor 1099 Int")
    begin
        Vendor1099Int.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Vendor1099Int.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099IntChangeCurrYearRPH(var Vendor1099Int: TestRequestPage "Vendor 1099 Int")
    begin
        Vendor1099Int.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Vendor1099Int.Year.SetValue(LibraryVariableStorage.DequeueText());
        Vendor1099Int.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099MiscRPH(var Vendor1099Misc: TestRequestPage "Vendor 1099 Misc")
    begin
        Vendor1099Misc.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Vendor1099Misc.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099Misc2020ChangeCurrYearRPH(var Vendor1099Misc2020: TestRequestPage "Vendor 1099 Misc 2020")
    begin
        Vendor1099Misc2020.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Vendor1099Misc2020.Year.SetValue(LibraryVariableStorage.DequeueText());
        Vendor1099Misc2020.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099Misc2021ChangeCurrYearRPH(var Vendor1099Misc2021: TestRequestPage "Vendor 1099 Misc 2021")
    begin
        Vendor1099Misc2021.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Vendor1099Misc2021.Year.SetValue(LibraryVariableStorage.DequeueText());
        Vendor1099Misc2021.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099Nec2022ChangeCurrYearRPH(var Vendor1099Nec2022: TestRequestPage "Vendor 1099 Nec 2022")
    begin
        Vendor1099Nec2022.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Vendor1099Nec2022.Year.SetValue(LibraryVariableStorage.DequeueText());
        Vendor1099Nec2022.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099Misc2022DoNothingRPH(var Vendor1099Misc2022: TestRequestPage "Vendor 1099 Misc 2022")
    begin
        Vendor1099Misc2022.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099NecRPH(var Vendor1099Nec: TestRequestPage "Vendor 1099 Nec")
    begin
        Vendor1099Nec.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Vendor1099Nec.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaRPH(var Vendor1099MagneticMedia: TestRequestPage "Vendor 1099 Magnetic Media")
    begin
        Vendor1099MagneticMedia.Year.SetValue(Date2DMY(WorkDate(), 3));
        Vendor1099MagneticMedia.TransCode.SetValue(CopyStr(LibraryUTUtility.GetNewCode(), 1, 5));
        Vendor1099MagneticMedia.ContactName.SetValue(LibraryUTUtility.GetNewCode());
        Vendor1099MagneticMedia.ContactPhoneNo.SetValue(LibraryUTUtility.GetNewCode());
        Vendor1099MagneticMedia.VendContactName.SetValue(LibraryUTUtility.GetNewCode());
        Vendor1099MagneticMedia.VendContactPhoneNo.SetValue(LibraryUTUtility.GetNewCode());
        Vendor1099MagneticMedia.VendorInfoName.SetValue(LibraryUTUtility.GetNewCode());
        Vendor1099MagneticMedia.VendorInfoAddress.SetValue(LibraryUTUtility.GetNewCode());
        Vendor1099MagneticMedia.VendorInfoCity.SetValue(LibraryUTUtility.GetNewCode());
        Vendor1099MagneticMedia.VendorInfoCounty.SetValue(LibraryUTUtility.GetNewCode());
        Vendor1099MagneticMedia.VendorInfoPostCode.SetValue(LibraryUTUtility.GetNewCode());
        Vendor1099MagneticMedia.VendorInfoEMail.SetValue(LibraryUTUtility.GetNewCode());

        Vendor1099MagneticMedia.VendorData.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Vendor1099MagneticMedia.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099Div2022RPH(var Vendor1099Div2022: TestRequestPage "Vendor 1099 Div 2022")
    begin
        Vendor1099Div2022.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Vendor1099Div2022.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099Div2021TestPrintRPH(var Vendor1099Div2021: TestRequestPage "Vendor 1099 Div 2021")
    begin
        Vendor1099Div2021.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Vendor1099Div2021.TestPrint.SetValue(true);
        Vendor1099Div2021.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099Div2022TestPrintRPH(var Vendor1099Div2022: TestRequestPage "Vendor 1099 Div 2022")
    begin
        Vendor1099Div2022.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Vendor1099Div2022.TestPrint.SetValue(true);
        Vendor1099Div2022.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099Int2022RPH(var Vendor1099Int2022: TestRequestPage "Vendor 1099 Int 2022")
    begin
        Vendor1099Int2022.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Vendor1099Int2022.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099Misc2022RPH(var Vendor1099Misc2022: TestRequestPage "Vendor 1099 Misc 2022")
    begin
        Vendor1099Misc2022.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Vendor1099Misc2022.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099Nec2022RPH(var Vendor1099Nec2022: TestRequestPage "Vendor 1099 Nec 2022")
    begin
        Vendor1099Nec2022.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Vendor1099Nec2022.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Vendor1099MagneticMediaRPH_Foreign(var Vendor1099MagneticMedia: TestRequestPage "Vendor 1099 Magnetic Media")
    var
        PostCode: Record "Post Code";
    begin
        PostCode.SetFilter("Country/Region Code", '<>%1&<>%2', 'US', 'USA');
        LibraryERM.FindPostCode(PostCode);
        Vendor1099MagneticMedia.VendorInfoCity.SetValue(PostCode.City);
        Vendor1099MagneticMedia.VendorInfoPostCode.SetValue(PostCode.Code);

        Vendor1099MagneticMedia.Year.SetValue(Date2DMY(WorkDate(), 3));
        Vendor1099MagneticMedia.TransCode.SetValue(CopyStr(LibraryUTUtility.GetNewCode(), 1, 5));
        Vendor1099MagneticMedia.ContactName.SetValue(LibraryUTUtility.GetNewCode());
        Vendor1099MagneticMedia.ContactPhoneNo.SetValue(LibraryUTUtility.GetNewCode());
        Vendor1099MagneticMedia.VendContactName.SetValue(LibraryUTUtility.GetNewCode());
        Vendor1099MagneticMedia.VendContactPhoneNo.SetValue(LibraryUTUtility.GetNewCode());
        Vendor1099MagneticMedia.VendorInfoName.SetValue(LibraryUTUtility.GetNewCode());
        Vendor1099MagneticMedia.VendorInfoAddress.SetValue(LibraryUTUtility.GetNewCode());
        Vendor1099MagneticMedia.VendorInfoCounty.SetValue(LibraryUTUtility.GetNewCode());
        Vendor1099MagneticMedia.VendorInfoEMail.SetValue(LibraryUTUtility.GetNewCode());

        Vendor1099MagneticMedia.VendorData.SetFilter("No.", LibraryVariableStorage.DequeueText());
        Vendor1099MagneticMedia.OK().Invoke();
    end;

    [MessageHandler]
    procedure UseNewIRSFormsFeatureMessageHandler(Message: Text)
    begin
        Assert.ExpectedMessage(UseNewIRSFormsFeatureMsg, Message);
    end;
}
#endif
