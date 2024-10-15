codeunit 145302 "BAS Reporting"
{
    // // [FEATURE] [BAS] [GST] [VAT Statement]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        WrongFilterValueErr: Label 'Wrong filter value';

    [Test]
    [Scope('OnPrem')]
    procedure UT_VATStatementLineBASAdjustField()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATStatementName: Record "VAT Statement Name";
    begin
        // [SCENARIO 263986] Field "BAS Adjustment" of VAT Statement Line can be filled
        Initialize;
        LibraryERM.CreateVATStatementNameWithTemplate(VATStatementName);
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name);
        VATStatementLine.TestField("BAS Adjustment", false);
        VATStatementLine."BAS Adjustment" := true;
        VATStatementLine.Modify;
        VATStatementLine.TestField("BAS Adjustment", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_VATReportHeaderBASIdBASVersionNoFields()
    var
        VATReportHeader: Record "VAT Report Header";
        BASCalculationSheet: Record "BAS Calculation Sheet";
        LibraryAPACLocalization: Codeunit "Library - APAC Localization";
    begin
        // [SCENARIO 263986] Fields BAS ID No. and BAS Version No. of VAT Report Header can be filled
        Initialize;
        CreateBASReport(VATReportHeader);
        VATReportHeader.TestField("BAS ID No.", '');
        VATReportHeader.TestField("BAS Version No.", 0);

        LibraryAPACLocalization.CreateBASCalculationSheet(BASCalculationSheet);
        VATReportHeader.Validate("BAS ID No.", BASCalculationSheet.A1);
        VATReportHeader.Validate("BAS Version No.", BASCalculationSheet."BAS Version");
        VATReportHeader.Modify;

        VATReportHeader.TestField("BAS ID No.", BASCalculationSheet.A1);
        VATReportHeader.TestField("BAS Version No.", BASCalculationSheet."BAS Version");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_VATReportHeaderBASIdBASVersionNoFieldsBASReportMandatory()
    var
        VATReportHeader: Record "VAT Report Header";
        BASCalculationSheet: Record "BAS Calculation Sheet";
        LibraryAPACLocalization: Codeunit "Library - APAC Localization";
    begin
        // [SCENARIO 263986] Fields BAS ID No. and BAS Version No. of VAT Report Header cannot be filled for VAT Report Config Code <> BAS Report
        Initialize;
        VATReportHeader.Init;
        VATReportHeader.Validate("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code"::"VAT Return");
        VATReportHeader.Insert(true);

        LibraryAPACLocalization.CreateBASCalculationSheet(BASCalculationSheet);
        Commit; // avoid transaction reverse when Error
        asserterror VATReportHeader.Validate("BAS ID No.", BASCalculationSheet.A1);
        Assert.ExpectedMessage(Format(VATReportHeader."VAT Report Config. Code"::"BAS Report"), GetLastErrorText);

        asserterror VATReportHeader.Validate("BAS Version No.", BASCalculationSheet."BAS Version");
        Assert.ExpectedMessage(Format(VATReportHeader."VAT Report Config. Code"::"BAS Report"), GetLastErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportHeaderBASReportNoSeries()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportSetup: Record "VAT Report Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        VATReportSetupPage: TestPage "VAT Report Setup";
        NoSeriesCode: Code[20];
        NextNo: Code[20];
    begin
        // [SCENARIO 263986] BAS Report "No." is generated using VAT Report Setup "BAS Report No. Series"
        Initialize;

        // [GIVEN] No Series "NS"
        NoSeriesCode := LibraryERM.CreateNoSeriesCode;
        NextNo := NoSeriesMgt.GetNextNo(NoSeriesCode, WorkDate, false);

        // [WHEN] "NS" is assigned to "BAS Report No. Series" of VAT Report Setup
        VATReportSetup.Get;
        VATReportSetup.Validate("BAS Report No. Series", NoSeriesCode);
        VATReportSetup.Modify;

        // [THEN] VAT Report Setup page "BAS Report No. Series" = NS
        VATReportSetupPage.OpenEdit;
        VATReportSetupPage."BAS Report No. Series".AssertEquals(NoSeriesCode);

        // [WHEN] New BAS Report is created
        CreateBASReport(VATReportHeader);

        // [THEN] "No." of the created BAS Report = No. from "NS" No. Series
        VATReportHeader.TestField("No.", NextNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_VATReportHeaderBASReportDefaultDateInit()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportsConfiguration: Record "VAT Reports Configuration";
        VATStatementName: Record "VAT Statement Name";
        VATReportsConfigurationPage: TestPage "VAT Reports Configuration";
    begin
        // [SCENARIO 263986] BAS Report Statement Name and Statement Template Name are taken from VAT Reports Configuration record
        Initialize;

        // [GIVEN] VAT Reports Configuration "VRC" with VAT Statement Name = "VSN", VAT Statement Template Name = "VSTN"
        LibraryERM.CreateVATStatementNameWithTemplate(VATStatementName);

        VATReportsConfiguration.SetRange("VAT Report Type", VATReportsConfiguration."VAT Report Type"::"BAS Report");
        VATReportsConfiguration.FindFirst;
        VATReportsConfiguration.Validate("VAT Statement Name", VATStatementName.Name);
        VATReportsConfiguration.Validate("VAT Statement Template", VATStatementName."Statement Template Name");
        VATReportsConfiguration.Modify;
        // [WHEN] VAT Reports Configuration page is opened for "VRC" record
        VATReportsConfigurationPage.OpenEdit;
        VATReportsConfigurationPage.GotoRecord(VATReportsConfiguration);

        // [THEN] VAT Statement Name = "VSN", VAT Statement Template Name = "VSTN"
        VATReportsConfigurationPage."VAT Statement Name".AssertEquals(VATStatementName.Name);
        VATReportsConfigurationPage."VAT Statement Template".AssertEquals(VATStatementName."Statement Template Name");

        // [WHEN] New BAS Report is created
        CreateBASReport(VATReportHeader);

        // [THEN] BAS Report has VAT Statement Name = "VSN", VAT Statement Template Name = "VSTN"
        VATReportHeader.TestField("Statement Name", VATStatementName.Name);
        VATReportHeader.TestField("Statement Template Name", VATStatementName."Statement Template Name");
    end;

    [Test]
    [HandlerFunctions('VATStatementTemplateListModalHandler')]
    [Scope('OnPrem')]
    procedure UI_VATStatementBASAdjustFieldVisible()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: array[2] of Record "VAT Statement Line";
        VATStatement: TestPage "VAT Statement";
    begin
        // [SCENARIO 263986] Field "BAS Adjustment" is visible and can show value on VAT Statement page
        Initialize;

        // [GIVEN] VAT Statement with line L1 that has BAS Adjustment = true, line L2 with BAS Adjustment = false
        LibraryERM.CreateVATStatementNameWithTemplate(VATStatementName);
        LibraryERM.CreateVATStatementLine(VATStatementLine[1], VATStatementName."Statement Template Name", VATStatementName.Name);
        VATStatementLine[1]."BAS Adjustment" := true;
        VATStatementLine[1].Modify;
        LibraryERM.CreateVATStatementLine(VATStatementLine[2], VATStatementName."Statement Template Name", VATStatementName.Name);

        // [WHEN] VAT Statement page is opened
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        VATStatement.OpenEdit;

        // [THEN] Line L1 has "BAS Adjustment" = TRUE
        VATStatement.GotoRecord(VATStatementLine[1]);
        VATStatement."BAS Adjustment".AssertEquals(true);

        // [THEN] Line L2 has "BAS Adjustment" = FALSE
        VATStatement.GotoRecord(VATStatementLine[2]);
        VATStatement."BAS Adjustment".AssertEquals(false);
    end;

    [Test]
    [HandlerFunctions('VATStatementTemplateListModalHandler')]
    [Scope('OnPrem')]
    procedure VATStatementPreviewBASAdjustment()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: array[2] of Record "VAT Statement Line";
        VATStatement: TestPage "VAT Statement";
        VATStatementPreview: TestPage "VAT Statement Preview";
        VATEntries: TestPage "VAT Entries";
    begin
        // [SCENARIO 263986] VAT Entries are filtered by BAS Adjustment field value when open from VAT Statement Preview
        Initialize;

        // [GIVEN] VAT Statement with line L1 that has BAS Adjustment = true, line L2 with BAS Adjustment = false
        LibraryERM.CreateVATStatementNameWithTemplate(VATStatementName);

        CreateVATStatementLine(
          VATStatementLine[1], VATStatementName."Statement Template Name", VATStatementName.Name,
          VATStatementLine[1].Type::"VAT Entry Totaling", '', true);
        CreateVATStatementLine(
          VATStatementLine[2], VATStatementName."Statement Template Name", VATStatementName.Name,
          VATStatementLine[2].Type::"VAT Entry Totaling", '', false);

        // [GIVEN] VAT Statement Preview page is opened
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");
        VATStatement.OpenEdit;
        VATStatementPreview.Trap;
        VATStatement."P&review".Invoke;
        VATStatementPreview.VATStatementLineSubForm.GotoRecord(VATStatementLine[1]);
        VATEntries.Trap;

        // [WHEN] Drill down on "Column Amount" is invoked on line L1
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.DrillDown;

        // [THEN] VAT Entries page is opened with filter on BAS Adjustment = TRUE
        Assert.AreEqual(Format(1), VATEntries.FILTER.GetFilter("BAS Adjustment"), WrongFilterValueErr);
        VATEntries.Close;
        VATStatementPreview.VATStatementLineSubForm.GotoRecord(VATStatementLine[2]);
        VATEntries.Trap;

        // [WHEN] Drill down on "Column Amount" is invoked on line L1
        VATStatementPreview.VATStatementLineSubForm.ColumnValue.DrillDown;

        // [THEN] VAT Entries page is opened with filter on BAS Adjustment = FALSE
        Assert.AreEqual(Format(0), VATEntries.FILTER.GetFilter("BAS Adjustment"), WrongFilterValueErr);

        VATEntries.Close;
        VATStatementPreview.Close;
        VATStatement.Close;
    end;

    [Test]
    [HandlerFunctions('VATReportRequesPageHandler')]
    [Scope('OnPrem')]
    procedure BASReportAmountEditable()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: array[2] of Record "VAT Statement Line";
        VATReportHeader: Record "VAT Report Header";
        VATStatementReportLine: Record "VAT Statement Report Line";
        BASReport: TestPage "VAT Report";
    begin
        // [SCENARIO 263986] Amount value is editable for lines of "Description" type
        Initialize;

        // [GIVEN] VAT Statement with line L1 that has Type = Row Totaling, line L2 with Type = Description
        LibraryERM.CreateVATStatementNameWithTemplate(VATStatementName);
        CreateVATStatementLine(
          VATStatementLine[1], VATStatementName."Statement Template Name", VATStatementName.Name,
          VATStatementLine[1].Type::"Row Totaling",
          CopyStr(LibraryUtility.GenerateRandomText(30), 1, MaxStrLen(VATStatementLine[1]."Box No.")), false);
        CreateVATStatementLine(
          VATStatementLine[2], VATStatementName."Statement Template Name", VATStatementName.Name,
          VATStatementLine[2].Type::Description,
          CopyStr(LibraryUtility.GenerateRandomText(30), 1, MaxStrLen(VATStatementLine[2]."Box No.")), false);

        UpdateVATReportsConfiguration(VATStatementName.Name, VATStatementName."Statement Template Name");
        // [GIVEN] BAS Report with suggested lines
        CreateBASReport(VATReportHeader);
        BASReportSuggestLines(BASReport, VATReportHeader);

        // [WHEN] Amount is edited for line with type "Row Totaling"
        FindVATStatementReportLine(
          VATStatementReportLine, VATReportHeader, VATStatementLine[1]."Box No.");
        BASReport.VATReportLines.GotoRecord(VATStatementReportLine);

        // [THEN] Error message appears stating it is not allowed to edit line with Type <> Description
        asserterror BASReport.VATReportLines.Amount.SetValue(5);
        Assert.ExpectedMessage(Format(VATStatementLine[1].Type::"Row Totaling"), GetLastErrorText);
        BASReport.Close;

        BASReport.OpenEdit;
        BASReport.GotoRecord(VATReportHeader);
        FindVATStatementReportLine(
          VATStatementReportLine, VATReportHeader, VATStatementLine[2]."Box No.");
        BASReport.VATReportLines.GotoRecord(VATStatementReportLine);

        // [WHEN] Amount = 10 is set for line with type "Description"
        BASReport.VATReportLines.Amount.SetValue(10);
        BASReport.Close;

        // [THEN] VAT Statement Report Line Amount = 10
        VATStatementReportLine.Find;
        VATStatementReportLine.TestField(Amount, 10);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BASReportOpenGSTPurchSalesPages()
    var
        VATReportHeader: Record "VAT Report Header";
        BASReport: TestPage "VAT Report";
        GSTPurchaseEntries: TestPage "GST Purchase Entries";
        GSTSalesEntries: TestPage "GST Sales Entries";
    begin
        // [SCENARIO 263986] Pages GST Sales Entries and GST Purchase Entries can be opened from BAS Report
        Initialize;

        // [GIVEN] BAS Report page
        CreateBASReport(VATReportHeader);
        BASReport.OpenEdit;
        BASReport.GotoRecord(VATReportHeader);

        // [WHEN] GST Sales Entries control is invoked
        GSTSalesEntries.Trap;
        BASReport."GST Sales Entries".Invoke;

        // [THEN] GST Sales Entries is opened
        GSTSalesEntries.Close;

        // [WHEN] GST Purchase Entries control is invoked
        GSTPurchaseEntries.Trap;
        BASReport."GST Purchase Entries".Invoke;

        // [THEN] GST Purchase Entries is opened
        GSTPurchaseEntries.Close;
        BASReport.Close;
    end;

    [Test]
    [HandlerFunctions('VATReportRequesPageHandler')]
    [Scope('OnPrem')]
    procedure BASReportRowTotalingDrillDown()
    var
        VATStatementLine: array[2] of Record "VAT Statement Line";
        RowTotalingVATStatementLine: Record "VAT Statement Line";
        VATStatementName: Record "VAT Statement Name";
        VATReportHeader: Record "VAT Report Header";
        VATBusinessPostingGroup: array[2] of Record "VAT Business Posting Group";
        VATProductPostingGroup: array[2] of Record "VAT Product Posting Group";
        VATStatementReportLine: Record "VAT Statement Report Line";
        VATEntry: array[2] of Record "VAT Entry";
        BASReport: TestPage "VAT Report";
        VATEntries: TestPage "VAT Entries";
    begin
        // [SCENARIO 263986] DrillDown on Amount of line with Row Totaling type
        Initialize;
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup[1]);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup[2]);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup[1]);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup[2]);

        // [GIVEN] VAT Statement Line "VSL1"
        LibraryERM.CreateVATStatementNameWithTemplate(VATStatementName);
        UpdateVATReportsConfiguration(VATStatementName.Name, VATStatementName."Statement Template Name");
        CreateVATStatementLine(
          VATStatementLine[1], VATStatementName."Statement Template Name", VATStatementName.Name,
          VATStatementLine[1].Type::"VAT Entry Totaling", '', false);
        VATStatementLine[1]."VAT Bus. Posting Group" := VATBusinessPostingGroup[1].Code;
        VATStatementLine[1]."VAT Prod. Posting Group" := VATProductPostingGroup[1].Code;
        VATStatementLine[1]."Row No." :=
          LibraryUtility.GenerateRandomCode(VATStatementLine[1].FieldNo("Row No."), DATABASE::"VAT Statement Line");
        VATStatementLine[1].Modify;

        // [GIVEN] VAT Statement Line "VSL2" with VAT groups different from "VSL1"
        CreateVATStatementLine(
          VATStatementLine[2], VATStatementName."Statement Template Name", VATStatementName.Name,
          VATStatementLine[2].Type::"VAT Entry Totaling", '', false);
        VATStatementLine[2]."VAT Bus. Posting Group" := VATBusinessPostingGroup[2].Code;
        VATStatementLine[2]."VAT Prod. Posting Group" := VATProductPostingGroup[2].Code;
        VATStatementLine[2]."Row No." := VATStatementLine[1]."Row No.";
        VATStatementLine[2].Modify;

        // [GIVEN] Row Totaling VAT Statement Line "RTVSL" that groups "VSL1" and "VSL2"
        CreateVATStatementLine(
          RowTotalingVATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name,
          RowTotalingVATStatementLine.Type::"Row Totaling",
          CopyStr(LibraryUtility.GenerateRandomText(30), 1, MaxStrLen(VATStatementLine[2]."Box No.")), false);
        RowTotalingVATStatementLine."Row Totaling" := VATStatementLine[1]."Row No.";
        RowTotalingVATStatementLine.Modify;

        // [GIVEN] VAT Entry "VE1" which corresponds to Statement Line "VSL1"
        CreateBASReport(VATReportHeader);
        MockVATEntry(
          VATEntry[1], VATBusinessPostingGroup[1].Code, VATProductPostingGroup[1].Code,
          VATReportHeader."Start Date", VATEntry[1].Type::Sale);
        // [GIVEN] VAT Entry "VE2" which corresponds to Statement Line "VSL2"
        MockVATEntry(
          VATEntry[2], VATBusinessPostingGroup[2].Code, VATProductPostingGroup[2].Code,
          VATReportHeader."Start Date", VATEntry[1].Type::Sale);

        // [WHEN] BAS Report suggested line for VAT Statement Line "RTVSL"
        BASReportSuggestLines(BASReport, VATReportHeader);

        // [THEN] VAT Statement Report line is suggested with Amount = "VE1".Amount + "VE2".Amount
        FindVATStatementReportLine(
          VATStatementReportLine, VATReportHeader, RowTotalingVATStatementLine."Box No.");
        BASReport.VATReportLines.GotoRecord(VATStatementReportLine);
        BASReport.VATReportLines.Amount.AssertEquals(VATEntry[1].Amount + VATEntry[2].Amount);
        VATEntries.Trap;

        // [WHEN] DrillDown on Amount field is invoked
        BASReport.VATReportLines.Amount.DrillDown;

        // [THEN] VAT Entry page appears with lines "VE1" and "VE2"
        VATEntries.GotoRecord(VATEntry[1]);
        VATEntries.Amount.AssertEquals(VATEntry[1].Amount);
        VATEntries.GotoRecord(VATEntry[2]);
        VATEntries.Amount.AssertEquals(VATEntry[2].Amount);
        VATEntries.Close;
        BASReport.Close;
    end;

    [Test]
    [HandlerFunctions('VATReportRequesPageHandler')]
    [Scope('OnPrem')]
    procedure BASReportGLAccTotalingDrillDown()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATStatementName: Record "VAT Statement Name";
        VATReportHeader: Record "VAT Report Header";
        VATStatementReportLine: Record "VAT Statement Report Line";
        GLEntry: Record "G/L Entry";
        BASReport: TestPage "VAT Report";
        GLEntries: TestPage "General Ledger Entries";
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 263986] DrillDown on Amount of line with Account Totaling
        GLAccountNo := LibraryERM.CreateGLAccountNo;

        // [GIVEN] VAT Statement Line "VSL1"
        LibraryERM.CreateVATStatementNameWithTemplate(VATStatementName);
        CreateVATStatementLine(
          VATStatementLine, VATStatementName."Statement Template Name", VATStatementName.Name,
          VATStatementLine.Type::"Account Totaling",
          CopyStr(LibraryUtility.GenerateRandomText(30), 1, MaxStrLen(VATStatementLine."Box No.")), false);
        VATStatementLine.Validate("Account Totaling", GLAccountNo);
        VATStatementLine.Modify;
        UpdateVATReportsConfiguration(VATStatementName.Name, VATStatementName."Statement Template Name");

        // [GIVEN] G/L Entry "GLE" which corresponds to Statement Line "VSL1"
        CreateBASReport(VATReportHeader);
        MockGLEntry(GLEntry, GLAccountNo, VATReportHeader."Start Date");

        // [WHEN] BAS Report suggested line for VAT Statement Line "VSL1"
        BASReportSuggestLines(BASReport, VATReportHeader);

        // [THEN] VAT Statement Report line is suggested with Amount = "GLE".Amount
        FindVATStatementReportLine(
          VATStatementReportLine, VATReportHeader, VATStatementLine."Box No.");
        BASReport.VATReportLines.GotoRecord(VATStatementReportLine);
        BASReport.VATReportLines.Amount.AssertEquals(GLEntry.Amount);
        GLEntries.Trap;

        // [WHEN] DrillDown on Amount field is invoked
        BASReport.VATReportLines.Amount.DrillDown;

        // [THEN] G/L Entries page is opened with G/L Entry "GLE"
        GLEntries.Amount.AssertEquals(GLEntry.Amount);
        GLEntries.Close;
        BASReport.Close;
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SeparateSettlePurchSalesGSTEntries()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: array[2] of Record "VAT Product Posting Group";
        VATEntry: array[2] of Record "VAT Entry";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
        SettlementAccountNo: Code[20];
    begin
        // [GST Settlement]
        // [SCENARIO 263986] GST Settlement G/L Entries Sales and Purchase entries posted separately
        Initialize;

        // [GIVEN] VAT Posting Setup "VPS1" with VAT Prod. Posting Group "VPPG1" and Bus. Posting Group "VBPG1", Sales VAT Account = "SVA1"
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup[1]);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup[1], VATBusinessPostingGroup.Code, VATProductPostingGroup[1].Code);
        VATPostingSetup[1]."Sales VAT Account" := LibraryERM.CreateGLAccountNo;
        VATPostingSetup[1].Modify;

        // [GIVEN] VAT Posting Setup "VPS2" with VAT Prod. Posting Group "VPPG2" and Bus. Posting Group "VBPG1", Purchase VAT Account = "PVA1"
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup[2]);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup[2], VATBusinessPostingGroup.Code, VATProductPostingGroup[2].Code);
        VATPostingSetup[2]."Purchase VAT Account" := LibraryERM.CreateGLAccountNo;
        VATPostingSetup[2].Modify;

        // [GIVEN] G/L Account "SettlementGLACC"
        SettlementAccountNo := LibraryERM.CreateGLAccountNo;

        // [GIVEN] VAT Entry "VE1" with Type Sale with Amount = "A1"
        MockVATEntry(
          VATEntry[1], VATBusinessPostingGroup.Code, VATProductPostingGroup[1].Code,
          WorkDate, VATEntry[1].Type::Sale);

        // [GIVEN] VAT Entry "VE2" with Type Sale with Amount = "A2"
        MockVATEntry(
          VATEntry[2], VATBusinessPostingGroup.Code, VATProductPostingGroup[2].Code,
          WorkDate, VATEntry[2].Type::Purchase);
        Commit;

        // [WHEN] Run Calc and Post GST Settlement for VAT Bus. Posting Group "VBPG1" and Settlement Account = "SettlementGLACC"
        CalcAndPostVATSettlement.InitializeRequest(WorkDate, WorkDate, WorkDate, SettlementAccountNo, SettlementAccountNo, true, true);
        VATPostingSetup[1].Reset;
        VATPostingSetup[1].SetRange("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        CalcAndPostVATSettlement.SetTableView(VATPostingSetup[1]);
        CalcAndPostVATSettlement.Run;

        // [THEN] G/L Entry with amount "A1" is posted to "SettlementGLACC" G/L Account
        VerifyGLEntryAccountAmount(SettlementAccountNo, VATEntry[1].Amount);
        VerifyGLEntryAccountAmount(SettlementAccountNo, VATEntry[2].Amount);

        // [THEN] G/L Entry with amount -"A1" is posted to "SVA1" G/L Account
        VerifyGLEntryAccountAmount(VATPostingSetup[1]."Sales VAT Account", -VATEntry[1].Amount);
        // [THEN] G/L Entry with amount -"A2" is posted to "PVA1" G/L Account
        VerifyGLEntryAccountAmount(VATPostingSetup[2]."Purchase VAT Account", -VATEntry[2].Amount);
    end;

    local procedure Initialize()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;

        if IsInitialized then
            exit;

        with GLSetup do begin
            Get;
            "Enable GST (Australia)" := true;
            Modify;
        end;

        LibrarySetupStorage.Save(DATABASE::"VAT Report Setup");
        IsInitialized := true;
    end;

    local procedure CreateBASReport(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.Init;
        VATReportHeader.Validate("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code"::"BAS Report");
        VATReportHeader.Insert(true);
    end;

    local procedure CreateVATStatementLine(var VATStatementLine: Record "VAT Statement Line"; StatementTemplateName: Code[10]; StatementName: Code[10]; Type: Option; BoxNo: Text[30]; BASAdjustment: Boolean)
    begin
        LibraryERM.CreateVATStatementLine(VATStatementLine, StatementTemplateName, StatementName);
        VATStatementLine.Validate(Type, Type);
        VATStatementLine.Validate("Box No.", BoxNo);
        VATStatementLine.Validate("BAS Adjustment", BASAdjustment);
        VATStatementLine.Validate("Amount Type", VATStatementLine."Amount Type"::Amount);
        VATStatementLine.Validate("Gen. Posting Type", VATStatementLine."Gen. Posting Type"::Sale);
        VATStatementLine.Modify;
    end;

    local procedure FindVATStatementReportLine(var VATStatementReportLine: Record "VAT Statement Report Line"; VATReportHeader: Record "VAT Report Header"; BoxNo: Text[30])
    begin
        VATStatementReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATStatementReportLine.SetRange("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code");
        VATStatementReportLine.SetRange("Box No.", BoxNo);
        VATStatementReportLine.FindFirst;
    end;

    local procedure MockGLEntry(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20]; PostingDate: Date)
    begin
        with GLEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(GLEntry, FieldNo("Entry No."));
            Amount := LibraryRandom.RandDec(30, 2);
            "Posting Date" := PostingDate;
            "G/L Account No." := GLAccountNo;
            Insert;
        end;
    end;

    local procedure MockVATEntry(var VATEntry: Record "VAT Entry"; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; PostingDate: Date; EntryType: Option)
    begin
        with VATEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(VATEntry, FieldNo("Entry No."));
            Type := Type;
            "Posting Date" := PostingDate;
            "Bill-to/Pay-to No." := LibrarySales.CreateCustomerNo;
            "VAT Bus. Posting Group" := VATBusPostingGroup;
            "VAT Prod. Posting Group" := VATProdPostingGroup;
            Base := LibraryRandom.RandDecInRange(10, 20, 2);
            Amount := LibraryRandom.RandDecInDecimalRange(1, Base, 2);
            Type := EntryType;
            Insert;
        end;
    end;

    local procedure UpdateVATReportsConfiguration(VATStatementName: Code[10]; VATStatementTemplateName: Code[10])
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        VATReportsConfiguration.SetRange("VAT Report Type", VATReportsConfiguration."VAT Report Type"::"BAS Report");
        VATReportsConfiguration.FindFirst;
        VATReportsConfiguration.Validate("VAT Statement Name", VATStatementName);
        VATReportsConfiguration.Validate("VAT Statement Template", VATStatementTemplateName);
        VATReportsConfiguration.Modify;
    end;

    local procedure VerifyGLEntryAccountAmount(GLAcccount: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAcccount);
        GLEntry.SetRange(Amount, Amount);
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    local procedure BASReportSuggestLines(var BASReport: TestPage "VAT Report"; VATReportHeader: Record "VAT Report Header")
    begin
        BASReport.OpenEdit;
        BASReport.GotoRecord(VATReportHeader);
        Commit;
        BASReport.SuggestLines.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATStatementTemplateListModalHandler(var VATStatementTemplateList: TestPage "VAT Statement Template List")
    var
        VATStatementNameVAR: Variant;
        VATStatementName: Code[20];
    begin
        LibraryVariableStorage.Dequeue(VATStatementNameVAR);
        Evaluate(VATStatementName, VATStatementNameVAR);
        VATStatementTemplateList.GotoKey(VATStatementName);
        VATStatementTemplateList.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATReportRequesPageHandler(var VATReportRequestPage: TestRequestPage "VAT Report Request Page")
    begin
        VATReportRequestPage.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementRequestPageHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    begin
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName)
    end;
}

