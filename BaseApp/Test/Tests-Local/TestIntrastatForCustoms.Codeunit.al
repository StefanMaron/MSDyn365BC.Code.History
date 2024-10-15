codeunit 144000 TestIntrastatForCustoms
{
    // // [FEATURE] [Intrastat]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateSetupRecordOnOpenPage()
    var
        IntrastatFileSetup: Record "Intrastat - File Setup";
        IntrastatFileSetupPage: TestPage "Intrastat - File Setup";
    begin
        Initialize;

        // Setup
        asserterror IntrastatFileSetup.Get;

        // Exercise
        IntrastatFileSetupPage.OpenEdit;
        IntrastatFileSetupPage.Close;

        // Verify
        IntrastatFileSetup.Get;

        // Cleanup
        IntrastatFileSetup.Delete;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateSetupRecordOnOpenPageWithExistingRec()
    var
        IntrastatFileSetup: Record "Intrastat - File Setup";
        IntrastatFileSetupPage: TestPage "Intrastat - File Setup";
    begin
        Initialize;

        // Setup
        asserterror IntrastatFileSetup.Get;
        IntrastatFileSetup.Insert;

        // Exercise
        IntrastatFileSetupPage.OpenEdit;
        IntrastatFileSetupPage.Close;

        // Verify
        Assert.AreEqual(1, IntrastatFileSetup.Count, 'Incorrect number of setup records created');

        // Cleanup
        IntrastatFileSetup.Delete;
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistRPH')]
    [Scope('OnPrem')]
    procedure IntrastatChecklistReportWithCountryRegionOfOriginCode()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatSetup: Record "Intrastat Setup";
    begin
        // [FEATURE] [Report] [Intrastat - Checklist] [Country/Region Code]
        // [SCENARIO 377083] "Country/Region Of Origin Code" is present on REP502 "Intrastat - Checklist"
        IntrastatSetup.DeleteAll;

        // [GIVEN] Country/Region Code "A", where Name = "B", "Intrastat Code" = C"
        // [GIVEN] Country/Region Code "X", where Name = "Y", "Intrastat Code" = Z"
        // [GIVEN] Intrastat Journal Line with "Country/Region Code" = "A" and "Country/Region of Origin Code" = "X"
        PrepareIntrastatJnlLineWithCountryRegionCodes(IntrastatJnlLine);

        // [WHEN] Run "Checklist Report" from Intrastat Journal Batch
        RunIntrastatChecklistReport(IntrastatJnlLine);

        // [THEN] "Country/Region Intrastat Code" = "C", "Country/Region Name" = "B"
        // [THEN] "Country/Region of Origin Intrastat Code" = "Z", "Country/Region Of Origin Name" = "Y"
        VerifyIntrastatChecklistReportCountryRegionCodes(
          GetIntrastatCode(IntrastatJnlLine."Country/Region Code"), GetName(IntrastatJnlLine."Country/Region Code"),
          GetIntrastatCode(IntrastatJnlLine."Country/Region of Origin Code"), GetName(IntrastatJnlLine."Country/Region of Origin Code"));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerIntrastatForm')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntrastatFormWithQuantity2Field()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        // [FEATURE] [Report] [Intrastat - Form]
        // [SCENARIO 380228] A "Quantity 2" field is shown in report "Intrastat - Form"
        Initialize;

        // [GIVEN] Intrastat Journal Line "INTJNL" with filled "Quantity 2" field.
        CreateIntrastatLineFilledForReportForm(IntrastatJnlLine);

        // [WHEN] Form report is executed for "INTJNL".
        RunIntrastatFormForIntrastatJnlLine(IntrastatJnlLine);

        // [THEN] Verify field "Quantity 2" is on "Intrastat - Form" report with appropriate value.
        VerifyQuantity2FieldIsOnIntrastatForm(IntrastatJnlLine."Quantity 2");
    end;

    [Test]
    [HandlerFunctions('IntrastatChecklistRPH')]
    [Scope('OnPrem')]
    procedure IntrastatChecklistReportCountryRegionOfOriginWithBlankIntrastatCode()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatSetup: Record "Intrastat Setup";
    begin
        // [FEATURE] [Report] [Intrastat - Checklist] [Country/Region Code]
        // [SCENARIO 263666] When report "Intrastat - Checklist" is run with specified Country/Region of Origin having <blank> "Intrastat Code", then Code is displayed in field "Country/Region of Origin Code" in report out
        IntrastatSetup.DeleteAll;

        // [GIVEN] Country/Region "X" with <blank> "Intrastat Code"
        // [GIVEN] Intrastat Journal Line with "Country/Region of Origin Code" = "X"
        PrepareIntrastatJnlLineWithCountryRegionCodes(IntrastatJnlLine);
        ClearIntrastatCode(IntrastatJnlLine."Country/Region of Origin Code");

        // [WHEN] Run "Checklist Report" from Intrastat Journal Batch
        RunIntrastatChecklistReport(IntrastatJnlLine);

        // [THEN] "Country/Region of Origin Intrastat Code" = "X" in report out
        VerifyIntrastatChecklistReportCountryRegionCodes(
          GetIntrastatCode(IntrastatJnlLine."Country/Region Code"), GetName(IntrastatJnlLine."Country/Region Code"),
          IntrastatJnlLine."Country/Region of Origin Code", GetName(IntrastatJnlLine."Country/Region of Origin Code"));
    end;

    local procedure Initialize()
    var
        IntrastatSetup: Record "Intrastat Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::TestIntrastatForCustoms);
        LibraryVariableStorage.Clear;
        IntrastatSetup.DeleteAll;

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::TestIntrastatForCustoms);

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;
        LibraryERMCountryData.CreateTransportMethodTableData;
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::TestIntrastatForCustoms);
    end;

    local procedure PrepareIntrastatJnlLineWithCountryRegionCodes(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        CountryRegion: Record "Country/Region";
        CountryRegionOfOrigin: Record "Country/Region";
    begin
        CreateCountryRegion(CountryRegion);
        CreateCountryRegion(CountryRegionOfOrigin);
        CreateIntrastatJnlLine(IntrastatJnlLine);
        IntrastatJnlLine.Validate("Country/Region Code", CountryRegion.Code);
        IntrastatJnlLine.Validate("Country/Region of Origin Code", CountryRegionOfOrigin.Code);
        IntrastatJnlLine.Modify;
    end;

    local procedure CreateCountryRegion(var CountryRegion: Record "Country/Region")
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        with CountryRegion do begin
            Validate(Name, LibraryUtility.GenerateGUID);
            Validate("Intrastat Code", LibraryUtility.GenerateGUID);
            Modify(true);
        end;
    end;

    local procedure CreateIntrastatLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; JournalDate: Date)
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        LibraryERM.CreateIntrastatJnlTemplate(IntrastatJnlTemplate);
        CreateAndUpdateIntrastatBatch(IntrastatJnlBatch, IntrastatJnlTemplate.Name, JournalDate);
        LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);
    end;

    local procedure CreateAndUpdateIntrastatBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; JournalTemplateName: Code[10]; JournalDate: Date)
    begin
        LibraryERM.CreateIntrastatJnlBatch(IntrastatJnlBatch, JournalTemplateName);
        IntrastatJnlBatch.Validate("Statistics Period", Format(JournalDate, 0, '<Year><Month,2>'));  // Take Value in YYMM format.
        IntrastatJnlBatch.Modify(true);
    end;

    local procedure CreateIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate);
        LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);

        with IntrastatJnlLine do begin
            "Tariff No." := LibraryUtility.GenerateGUID;
            "Transaction Type" := LibraryUtility.GenerateGUID;
            "Transport Method" := LibraryUtility.GenerateGUID;
            Validate(Quantity, LibraryRandom.RandInt(10));
            Validate("Net Weight", LibraryRandom.RandInt(10));
            Modify(true);
        end;
    end;

    local procedure CreateIntrastatLineFilledForReportForm(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        CountryRegion: Record "Country/Region";
    begin
        CreateIntrastatLine(IntrastatJnlLine, WorkDate);
        with IntrastatJnlLine do begin
            Validate(Type, Type::Receipt);
            Validate(Date, WorkDate);
            CreateCountryRegion(CountryRegion);
            Validate("Country/Region Code", CountryRegion.Code);
            Validate("Tariff No.", LibraryUtility.FindOrCreateCodeRecord(DATABASE::"Tariff Number"));
            Validate("Transaction Type", LibraryUtility.CreateCodeRecord(DATABASE::"Transaction Type"));
            Validate("Transport Method", LibraryUtility.CreateCodeRecord(DATABASE::"Transport Method"));
            Validate(Quantity, LibraryRandom.RandIntInRange(10, 1000));
            Validate("Quantity 2", LibraryRandom.RandIntInRange(10, 1000));
            Validate("Net Weight", LibraryRandom.RandIntInRange(10, 1000));
            Modify(true);
        end;
    end;

    local procedure GetIntrastatCode(CountryCode: Code[10]): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(CountryCode);
        exit(CountryRegion."Intrastat Code");
    end;

    local procedure GetName(CountryCode: Code[10]): Text[50]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(CountryCode);
        exit(CountryRegion.Name);
    end;

    local procedure ClearIntrastatCode(CountryCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(CountryCode);
        CountryRegion.Validate("Intrastat Code", '');
        CountryRegion.Modify(true);
    end;

    local procedure RunIntrastatChecklistReport(IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        Commit;
        IntrastatJnlBatch.SetRange("Journal Template Name", IntrastatJnlLine."Journal Template Name");
        IntrastatJnlBatch.SetRange(Name, IntrastatJnlLine."Journal Batch Name");
        REPORT.Run(REPORT::"Intrastat - Checklist", true, false, IntrastatJnlBatch);
    end;

    local procedure RunIntrastatFormForIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        IntrastatJnlLine.SetRange(Type, IntrastatJnlLine.Type::Receipt);
        REPORT.Run(REPORT::"Intrastat - Form", true, false, IntrastatJnlLine);
    end;

    local procedure VerifyQuantity2FieldIsOnIntrastatForm(Quantity: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('Quantity2_IntraJnlLine', Quantity);
    end;

    local procedure VerifyIntrastatChecklistReportCountryRegionCodes(CountryIntrastatCode: Code[10]; CountryName: Text[50]; CountryOfOriginCode: Code[10]; CountryOfOriginName: Text[50])
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.GetNextRow;
        LibraryReportDataset.AssertCurrentRowValueEquals('CountryIntrastatCode', CountryIntrastatCode);
        LibraryReportDataset.AssertCurrentRowValueEquals('CountryName', CountryName);
        LibraryReportDataset.AssertCurrentRowValueEquals('CountryRegionOfOriginIntrastatCode', CountryOfOriginCode);
        LibraryReportDataset.AssertCurrentRowValueEquals('CountryRegionOfOriginName', CountryOfOriginName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatChecklistRPH(var IntrastatChecklist: TestRequestPage "Intrastat - Checklist")
    begin
        IntrastatChecklist.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerIntrastatForm(var IntrastatForm: TestRequestPage "Intrastat - Form")
    begin
        IntrastatForm.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

