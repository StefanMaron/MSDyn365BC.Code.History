codeunit 18912 "TCS-Preparation"
{
    Subtype = Test;
    [Test]
    [HandlerFunctions('TaxRatePageHandler')]
    procedure CreateTCSSetup()
    var
        TCSNatureOfCollection: Record "TCS Nature Of Collection";
        AssesseeCode: Record "Assessee Code";
        ConcessionalCode: Record "Concessional Code";
    begin
        // [Scenario 354739] Check if the program is allowing you to design the TCS Posting Setup, TCS Rates, TCS NOC, Concessional Codes, Assessee Codes, TCAN No.

        // [GIVEN] Create TCS posting setup, TCS Rates, TCS Nature of Collection, Concessional Code, Assessee Code
        // [WHEN] TCS Setup Created- TCS posting setup, TCS Rates, TCS Nature of Collection, Concessional Code, Assessee Code
        CreateTCSNatureOfCollection(TCSNatureOfCollection);
        CreateTCSPostingSetup(TCSNatureOfCollection.Code);
        CreateAssesseeCode(AssesseeCode);
        CreateTCANNo();
        CreateConcessionalCode(ConcessionalCode);
        CreateTCSRates(TCSNatureOfCollection.Code, AssesseeCode.Code, ConcessionalCode.Code, WorkDate());

        // [THEN] TCS Setup Verified
        VerifyTCSSetup(TCSNatureOfCollection.Code, AssesseeCode.Code, ConcessionalCode.Code);
    end;

    [Test]
    procedure InsertTCSDetailsonCompanyInformation()
    var
        CompInfo: Record "Company Information";
        GSTRegistrationNos: Record "GST Registration Nos.";
    begin
        // [Scenario 354740] Check if the program is allowing you to design the TDS/TCS related fields in Company Information

        // [GIVEN] TCS Setup create for Company Information
        // [WHEN] TCS Setup created for Company Information
        Compinfo.get();
        if Compinfo."GST Registration No." = '' then begin
            if GSTRegistrationNos.FindFirst() then
                CompInfo.Validate("P.A.N. No.", CopyStr(GSTRegistrationNos.Code, 3, 10))
            else
                CompInfo.Validate("P.A.N. No.", LibraryUtility.GenerateRandomCode(CompInfo.FieldNo("P.A.N. No."), Database::"Company Information"));
        end else
            CompInfo.Validate("P.A.N. No.", CopyStr(CompInfo."GST Registration No.", 3, 10));
        CompInfo.Validate("Circle No.", LibraryUtility.GenerateRandomText(30));
        CompInfo.Validate("Ward No.", LibraryUtility.GenerateRandomText(30));
        CompInfo.Validate("Assessing Officer", LibraryUtility.GenerateRandomText(30));
        CompInfo.Validate("Deductor Category", CreateDeductorCategory());
        if CompInfo."State Code" = '' then
            CompInfo.Validate("State Code", CreateStateCode());
        CompInfo.Validate("T.C.A.N. No.", CreateTCANNo());
        CompInfo.Modify(true);

        // [THEN] Company Information Verified
        VerifyCompanyInformation();
    end;

    local procedure CreateStateCode(): Code[10]
    var
        State: Record State;
    begin
        if State.FindFirst() then
            exit(State.Code)
        else begin
            State.Init();
            State.Validate(Code, LibraryRandom.RandText(2));
            State.Validate(Description, State.Code);
            State.Insert(true);
            exit(State.Code);
        end;
    end;

    local procedure CreateDeductorCategory(): Code[20]
    var
        DeductorCategory: Record "Deductor Category";
    begin
        DeductorCategory.SetRange("DDO Code Mandatory", false);
        DeductorCategory.SetRange("PAO Code Mandatory", false);
        DeductorCategory.SetRange("State Code Mandatory", false);
        DeductorCategory.SetRange("Ministry Details Mandatory", false);
        DeductorCategory.SetRange("Transfer Voucher No. Mandatory", false);
        if DeductorCategory.FindFirst() then
            exit(DeductorCategory.Code)
        else begin
            DeductorCategory.Init();
            DeductorCategory.Validate(Code, LibraryUtility.GenerateRandomText(1));
            DeductorCategory.Insert(true);
            exit(DeductorCategory.Code);
        end;
    end;

    procedure CreateTCSNatureOfCollection(var TCSNatureOfCollection: Record "TCS Nature Of Collection")
    begin
        TCSNatureOfCollection.Init();
        TCSNatureOfCollection.Validate(Code, LibraryUtility.GenerateRandomCode(TCSNatureOfCollection.FIELDNO(Code), DATABASE::"TCS Nature Of Collection"));
        TCSNatureOfCollection.Validate(Description, TCSNatureOfCollection.Code);
        TCSNatureOfCollection.Insert(true);
    end;

    local procedure CreateTCSPostingSetup(TCSNatureOfCollectionCode: Code[20])
    var
        TCSPostingSetup: Record "TCS Posting Setup";
    begin
        TCSPostingSetup.Init();
        TCSPostingSetup.Validate("TCS Nature of Collection", TCSNatureOfCollectionCode);
        TCSPostingSetup.Validate("Effective Date", WorkDate());
        TCSPostingSetup.Validate("TCS Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        TCSPostingSetup.Insert(true);
    end;

    local procedure CreateAssesseeCode(var AssesseeCode: Record "Assessee Code")
    begin
        AssesseeCode.Init();
        AssesseeCode.Validate(Code, LibraryUtility.GenerateRandomCode(AssesseeCode.FieldNo(Code), Database::"Assessee Code"));
        AssesseeCode.Validate(Description, AssesseeCode.Code);
        AssesseeCode.Insert(true);
    end;

    local procedure CreateTCANNo(): Code[10]
    var
        TCANNo: Record "T.C.A.N. No.";
    begin
        TCANNo.INIT();
        TCANNo.Validate(Code, LibraryUtility.GenerateRandomCode(TCANNo.FIELDNO(Code), DATABASE::"T.C.A.N. No."));
        TCANNo.Validate(Description, TCANNo.Code);
        TCANNo.Insert(true);
        exit(TCANNo.Code);
    end;

    local procedure CreateConcessionalCode(var ConcessionalCode: Record "Concessional Code")
    begin
        ConcessionalCode.Init();
        ConcessionalCode.Validate(Code, LibraryUtility.GenerateRandomCode(ConcessionalCode.FIELDNO(Code), DATABASE::"Concessional Code"));
        ConcessionalCode.Validate(Description, ConcessionalCode.Code);
        ConcessionalCode.Insert(true);
    end;

    [PageHandler]
    procedure TaxRatePageHandler(var TaxRate: TestPage "Tax Rates");
    var
        EffectiveDate: Date;
    begin
        Evaluate(EffectiveDate, Storage.Get('EffectiveDate'));

        TaxRate.AttributeValue1.SetValue(Storage.Get('TCSNOCType'));
        TaxRate.AttributeValue2.SetValue(Storage.Get('TCSAssesseeCode'));
        TaxRate.AttributeValue3.SetValue(Storage.Get('TCSConcessionalCode'));
        TaxRate.AttributeValue4.SetValue(EffectiveDate);
        TaxRate.AttributeValue5.SetValue(LibraryRandom.RandIntInRange(2, 4));
        TaxRate.AttributeValue6.SetValue(LibraryRandom.RandIntInRange(8, 10));
        TaxRate.AttributeValue7.SetValue(LibraryRandom.RandIntInRange(8, 10));
        TaxRate.AttributeValue8.SetValue(LibraryRandom.RandIntInRange(1, 2));
        TaxRate.AttributeValue9.SetValue(LibraryRandom.RandIntInRange(1, 2));
        TaxRate.AttributeValue10.SetValue(LibraryRandom.RandIntInRange(8000, 10000));
        TaxRate.AttributeValue11.SetValue(LibraryRandom.RandIntInRange(8000, 10000));
        TaxRate.OK().Invoke();
    end;

    local procedure CreateTCSRates(TCSNOC: Code[10]; AssesseeCode: Code[10]; ConcessionalCode: Code[10]; EffectiveDate: Date)
    begin
        Storage.Set('TCSNOCType', TCSNOC);
        Storage.Set('TCSAssesseeCode', AssesseeCode);
        Storage.Set('TCSConcessionalCode', ConcessionalCode);
        Storage.Set('EffectiveDate', Format(EffectiveDate));
        CreateTaxRate();
    end;

    Local procedure CreateTaxRate()
    var
        TCSSetup: Record "TCS Setup";
        PageTaxtype: TestPage "Tax Types";
    begin
        if not TCSSetup.Get() then
            exit;
        PageTaxtype.OpenEdit();
        PageTaxtype.Filter.SetFilter(Code, TCSSetup."Tax Type");
        PageTaxtype.TaxRates.Invoke();
    end;

    local procedure VerifyTCSSetup(
        TCSNOC: Code[10];
        AssesseeCode: Code[10];
        ConcessinalCode: Code[10])
    var
        TCSNatureOfCollection: Record "TCS Nature Of Collection";
        AssesseeCodes: Record "Assessee Code";
        ConcessionalCodes: Record "Concessional Code";
    begin
        TCSNatureOfCollection.Get(TCSNOC);
        AssesseeCodes.Get(AssesseeCode);
        ConcessionalCodes.Get(ConcessinalCode);
    end;

    local procedure VerifyCompanyInformation()
    var
        CompInfo: Record "Company Information";
    begin
        CompInfo.SetFilter("P.A.N. No.", '<>%1', '');
        CompInfo.SetFilter("Circle No.", '<>%1', '');
        CompInfo.SetFilter("Ward No.", '<>%1', '');
        CompInfo.SetFilter("State Code", '<>%1', '');
        CompInfo.SetFilter("T.C.A.N. No.", '<>%1', '');
        CompInfo.SetFilter("Assessing Officer", '<>%1', '');
        CompInfo.SetFilter("Deductor Category", '<>%1', '');
        if CompInfo.IsEmpty then
            Error(CompanySetupErr);
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Storage: Dictionary of [Text, Text];
        CompanySetupErr: Label 'Company Information setup not created', Locked = true;
}