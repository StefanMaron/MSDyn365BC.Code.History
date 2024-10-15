codeunit 145301 "BAS Managament"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [BAS Calculation Sheet]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        BASCalcSheetUpdatedErr: Label 'The BAS calculation sheet was not updated.';
        BASCalcSheetConsolidatedErr: Label 'The BAS calculation sheet was not consolidated.';
        BASCalcSheetGroupConsolidatedErr: Label 'The BAS calculation sheet was not group consolidated.';
        BASCalcSheetConsolidatedSumErr: Label 'The consolidation sum of the BAS calculation sheet is wrong.';
        VarStorage: Codeunit "Library - Variable Storage";
        ExportedBASCalcSheetErr: Label 'The BAS calculation sheet cannot be exported.';
        CannotEditFieldErr: Label 'You cannot edit this field. Use the import function.';

#if not CLEAN19
    [Test]
    [HandlerFunctions('MPHBASCalcSheduleList,RPHBASUpdate,MessageHandler')]
    [Scope('OnPrem')]
    procedure ImportSubsidiaries()
    var
        BASMgt: Codeunit "BAS Management";
        BASVersion: Integer;
        T2Value: Decimal;
        DocumentNo: Code[11];
    begin
        // Initialize
        InitScenarioImportSubsidiaries(DocumentNo, BASVersion, T2Value);

        // Excercise
        BASMgt.ImportSubsidiaries;

        // Test
        VerifyScenarioImportSubsidiaries(DocumentNo, BASVersion, T2Value);
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    procedure BanOnSettingValue()
    var
        BASCalculationSheet: TestPage "BAS Calculation Sheet";
    begin
        // [SCENARIO 379595] Check the ban on setting the value in the field A1

        Initialize;

        // [GIVEN] Open BAS Calculation Sheet
        BASCalculationSheet.OpenNew;

        // [WHEN] Setting value in field A1.
        asserterror BASCalculationSheet.A1.SetValue(LibraryUtility.GenerateRandomText(10));

        // [THEN] Verify error message appeared: 'You cannot edit this field. Use the import function'
        Assert.ExpectedError(CannotEditFieldErr);
    end;

    local procedure Initialize()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        with GLSetup do begin
            Get;
            "Enable GST (Australia)" := true;
            "BAS to be Lodged as a Group" := true;
            "BAS Group Company" := true;
            Modify;
        end;
    end;

    local procedure InitScenarioImportSubsidiaries(var DocumentNo: Code[11]; var BASVersion: Integer; var T2Value: Decimal)
    var
        BASCalcSheet: Record "BAS Calculation Sheet";
        BASSetupName: Record "BAS Setup Name";
        SetupName: Code[20];
    begin
        Initialize;
        BASVersion := LibraryRandom.RandInt(10);
        CreateBASSetupName(BASSetupName);
        SetupName := BASSetupName.Name;
        T2Value := LibraryRandom.RandDec(100, 2);
        InitBASCalcSheet(BASCalcSheet, BASVersion, SetupName, T2Value);
        DocumentNo := BASCalcSheet.A1;
        InitBASBusinessUnit(BASCalcSheet);
        VarStorage.Enqueue(DocumentNo);
        VarStorage.Enqueue(BASVersion);
        VarStorage.Enqueue(SetupName);
    end;

    local procedure VerifyScenarioImportSubsidiaries(DocumentNo: Code[11]; BASVersion: Integer; T2Value: Decimal)
    var
        BASCalcSheet: Record "BAS Calculation Sheet";
    begin
        Commit();
        BASCalcSheet.Get(DocumentNo, BASVersion);
        Assert.AreEqual(true, BASCalcSheet.Updated, BASCalcSheetUpdatedErr);
        Assert.AreEqual(true, BASCalcSheet.Consolidated, BASCalcSheetConsolidatedErr);
        Assert.AreEqual(true, BASCalcSheet."Group Consolidated", BASCalcSheetGroupConsolidatedErr);
        Assert.AreEqual(T2Value, BASCalcSheet.T2, BASCalcSheetConsolidatedSumErr);
    end;

    local procedure InitBASCalcSheet(var BASCalcSheet: Record "BAS Calculation Sheet"; BASVersion: Integer; BASSetupName: Code[20]; T2Value: Decimal)
    var
        GLSetup: Record "General Ledger Setup";
        CompanyInformation: Record "Company Information";
        DocumentNo: Code[11];
    begin
        DocumentNo :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(BASCalcSheet.FieldNo(A1), DATABASE::"BAS Calculation Sheet"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"BAS Calculation Sheet", BASCalcSheet.FieldNo(A1)));

        CompanyInformation.Get();
        with BASCalcSheet do begin
            Init;
            A1 := DocumentNo;
            "BAS Version" := BASVersion;
            A2 := CompanyInformation.ABN;
            A2a := CompanyInformation."ABN Division Part No.";
            A3 := 20110101D;
            A4 := 20110131D;
            A5 := 20110128D;
            A6 := 20110128D;
            T2 := T2Value;
            GLSetup.Get();
            "BAS GST Division Factor" := GLSetup."BAS GST Division Factor";
            "BAS Setup Name" := BASSetupName;
            Insert;
        end;
    end;

    local procedure InitBASBusinessUnit(BASCalcSheet: Record "BAS Calculation Sheet")
    var
        BASBusinessUnit: Record "BAS Business Unit";
    begin
        with BASBusinessUnit do begin
            Init;
            "Company Name" := CompanyName;
            "Document No." := BASCalcSheet.A1;
            "BAS Version" := BASCalcSheet."BAS Version";
            Insert;
        end;
    end;

#if not CLEAN19
    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHBASUpdate(var RequestPage: TestRequestPage "BAS-Update")
    var
        FileMgt: Codeunit "File Management";
        SetupNameVar: Variant;
        SetupName: Code[11];
        ReportFilePath: Text;
    begin
        VarStorage.Dequeue(SetupNameVar);
        Evaluate(SetupName, SetupNameVar);
        RequestPage."BAS Setup".SetFilter("Setup Name", SetupName);
        ReportFilePath := StrSubstNo('%1\%2.pdf', TemporaryPath, RequestPage.Caption);
        RequestPage.SaveAsPdf(ReportFilePath);
        FileMgt.DeleteClientFile(ReportFilePath);
    end;
#endif

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MPHBASCalcSheduleList(var TestPage: TestPage "BAS Calc. Schedule List")
    var
        BASCalcSheet: Record "BAS Calculation Sheet";
        BASUpdate: Report "BAS-Update";
        DocumentNoVar: Variant;
        BASVersionVar: Variant;
        DocumentNo: Code[11];
        BASVersion: Integer;
    begin
        VarStorage.Dequeue(DocumentNoVar);
        Evaluate(DocumentNo, DocumentNoVar);
        VarStorage.Dequeue(BASVersionVar);
        Evaluate(BASVersion, Format(BASVersionVar));

        BASCalcSheet.Get(DocumentNo, BASVersion);
        with BASCalcSheet do begin
            Commit();
            Assert.AreEqual(false, Exported, ExportedBASCalcSheetErr);
            Clear(BASUpdate);
            BASUpdate.InitializeRequest(
                BASCalcSheet, true, "VAT Statement Report Selection"::Open, "VAT Statement Report Period Selection"::"Before and Within Period", false);
            BASUpdate.UseRequestPage(true);
            BASUpdate.RunModal;
        end;

        TestPage.GotoRecord(BASCalcSheet);
        TestPage.OK.Invoke;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
        // stub for message handling
    end;

    local procedure CreateBASSetupName(var BASSetupName: Record "BAS Setup Name")
    begin
        BASSetupName.Init();
        BASSetupName.Name := LibraryUtility.GenerateRandomCode(BASSetupName.FieldNo(Name), DATABASE::"BAS Setup Name");
        BASSetupName.Insert();
    end;
}

