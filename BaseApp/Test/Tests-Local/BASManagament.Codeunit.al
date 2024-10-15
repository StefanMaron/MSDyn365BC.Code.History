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
        CannotEditFieldErr: Label 'You cannot edit this field. Use the import function.';

    [Test]
    [Scope('OnPrem')]
    procedure BanOnSettingValue()
    var
        BASCalculationSheet: TestPage "BAS Calculation Sheet";
    begin
        // [SCENARIO 379595] Check the ban on setting the value in the field A1

        Initialize();

        // [GIVEN] Open BAS Calculation Sheet
        BASCalculationSheet.OpenNew();

        // [WHEN] Setting value in field A1.
        asserterror BASCalculationSheet.A1.SetValue(LibraryUtility.GenerateRandomText(10));

        // [THEN] Verify error message appeared: 'You cannot edit this field. Use the import function'
        Assert.ExpectedError(CannotEditFieldErr);
    end;

    local procedure Initialize()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."Enable GST (Australia)" := true;
        GLSetup."BAS to be Lodged as a Group" := true;
        GLSetup."BAS Group Company" := true;
        GLSetup.Modify();
    end;

    local procedure InitScenarioImportSubsidiaries(var DocumentNo: Code[11]; var BASVersion: Integer; var T2Value: Decimal)
    var
        BASCalcSheet: Record "BAS Calculation Sheet";
        BASSetupName: Record "BAS Setup Name";
        SetupName: Code[20];
    begin
        Initialize();
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
        BASCalcSheet.Init();
        BASCalcSheet.A1 := DocumentNo;
        BASCalcSheet."BAS Version" := BASVersion;
        BASCalcSheet.A2 := CompanyInformation.ABN;
        BASCalcSheet.A2a := CompanyInformation."ABN Division Part No.";
        BASCalcSheet.A3 := 20110101D;
        BASCalcSheet.A4 := 20110131D;
        BASCalcSheet.A5 := 20110128D;
        BASCalcSheet.A6 := 20110128D;
        BASCalcSheet.T2 := T2Value;
        GLSetup.Get();
        BASCalcSheet."BAS GST Division Factor" := GLSetup."BAS GST Division Factor";
        BASCalcSheet."BAS Setup Name" := BASSetupName;
        BASCalcSheet.Insert();
    end;

    local procedure InitBASBusinessUnit(BASCalcSheet: Record "BAS Calculation Sheet")
    var
        BASBusinessUnit: Record "BAS Business Unit";
    begin
        BASBusinessUnit.Init();
        BASBusinessUnit."Company Name" := CompanyName;
        BASBusinessUnit."Document No." := BASCalcSheet.A1;
        BASBusinessUnit."BAS Version" := BASCalcSheet."BAS Version";
        BASBusinessUnit.Insert();
    end;

    local procedure CreateBASSetupName(var BASSetupName: Record "BAS Setup Name")
    begin
        BASSetupName.Init();
        BASSetupName.Name := LibraryUtility.GenerateRandomCode(BASSetupName.FieldNo(Name), DATABASE::"BAS Setup Name");
        BASSetupName.Insert();
    end;
}

