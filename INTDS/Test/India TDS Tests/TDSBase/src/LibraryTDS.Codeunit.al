codeunit 18786 "Library-TDS"
{
    procedure CreateTDSSetup(var Vendor: Record Vendor; var TDSPostingSetup: Record "TDS Posting Setup"; var ConcessionalCode: Record "Concessional Code")
    var
        AssesseeCode: Record "Assessee Code";
        TDSSection: Record "TDS Section";
    begin
        CreateCommonSetup(AssesseeCode, ConcessionalCode);
        CreateTDSPostingSetupWithSection(TDSPostingSetup, TDSSection);
        CreateTDSVendor(Vendor, AssesseeCode.Code, TDSSection.Code);
        AttachConcessionalWithVendor(Vendor."No.", ConcessionalCode.Code, TDSSection.Code);
    end;

    local procedure CreateCommonSetup(var AssesseeCode: Record "Assessee Code"; var ConcessionalCode: Record "Concessional Code")
    begin
        if IsTaxAccountingPeriodEmpty() then
            CreateTDSAccountingPeriod();
        CreateAssesseeCode(AssesseeCode);
        InsertCompanyInformationDetails();
        CreateConcessionalCode(ConcessionalCode);
    end;

    local procedure CreateTDSVendor(var Vendor: Record Vendor; AssesseeCode: Code[10]; TDSSection: Code[10]);
    var
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreateZeroVATPostingSetup(VATPostingSetup);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate("Assessee Code", AssesseeCode);
        UpdateTDSSectionOnVendor(Vendor."No.", TDSSection);
        Vendor.Modify(true);
    end;

    procedure UpdateVendorWithPANWithConcessional(Var Vendor: Record Vendor; ThresholdOverlook: Boolean; SurchargeOverlook: Boolean)
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        Vendor.Validate("P.A.N. No.", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("P.A.N. No."), Database::Vendor));
        Vendor.Modify(true);
        UpdateTDSSectionOnVendor(Vendor."No.", ThresholdOverlook, SurchargeOverlook);
    end;

    procedure UpdateVendorWithPANWithOutConcessional(Var Vendor: Record Vendor; ThresholdOverlook: Boolean; SurchargeOverlook: Boolean)
    var
        TDSConcessionlCode: Record "TDS Concessional Code";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        Vendor.Validate("P.A.N. No.", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("P.A.N. No."), Database::Vendor));
        Vendor.Modify(true);
        UpdateTDSSectionOnVendor(Vendor."No.", ThresholdOverlook, SurchargeOverlook);

        TDSConcessionlCode.SetRange("Vendor No.", Vendor."No.");
        TDSConcessionlCode.DeleteAll(true);
    end;

    procedure UpdateVendorWithoutPANWithConcessional(Var Vendor: Record Vendor; ThresholdOverlook: Boolean; SurchargeOverlook: Boolean)
    var
        LibraryRandom: Codeunit "Library - Random";
    begin
        Vendor.Validate("P.A.N. Status", Vendor."P.A.N. Status"::PANAPPLIED);
        Vendor.Validate("P.A.N. Reference No.", LibraryRandom.RandText(10));
        Vendor.Modify(true);
        UpdateTDSSectionOnVendor(Vendor."No.", ThresholdOverlook, SurchargeOverlook);
    end;

    procedure UpdateVendorWithoutPANWithoutConcessional(Var Vendor: Record Vendor; ThresholdOverlook: Boolean; SurchargeOverlook: Boolean)
    var
        TDSConcessionlCode: Record "TDS Concessional Code";
        LibraryRandom: Codeunit "Library - Random";
    begin
        Vendor.Validate("P.A.N. Status", Vendor."P.A.N. Status"::PANAPPLIED);
        Vendor.Validate("P.A.N. Reference No.", LibraryRandom.RandText(10));
        Vendor.Modify(true);
        UpdateTDSSectionOnVendor(Vendor."No.", ThresholdOverlook, SurchargeOverlook);

        TDSConcessionlCode.SetRange("Vendor No.", Vendor."No.");
        TDSConcessionlCode.DeleteAll(true);
    end;

    local procedure UpdateTDSSectionOnVendor(VendorNo: Code[20]; ThresholdOverLook: Boolean; SurchargeOverlook: Boolean)
    var
        AllowedSections: Record "Allowed Sections";
    begin
        AllowedSections.SetRange("Vendor No", VendorNo);
        AllowedSections.FindFirst();
        AllowedSections.Validate("Threshold Overlook", ThresholdOverlook);
        AllowedSections.Validate("Surcharge Overlook", SurchargeOverlook);
        AllowedSections.Modify(true);
    end;

    local procedure UpdateTDSSectionOnVendor(VendorNo: Code[20]; TDSSection: Code[10])
    var
        AllowedSections: Record "Allowed Sections";
    begin
        AllowedSections.Init();
        AllowedSections.Validate("Vendor No", VendorNo);
        AllowedSections.Validate("TDS Section", TDSSection);
        AllowedSections.Validate("Default Section", true);
        AllowedSections.Insert(true);
    end;

    procedure AttachConcessionalWithVendor(VendorNo: Code[20]; ConcessionalCode: Code[10]; TDSSection: Code[10])
    var
        TDSConcessionlCode: Record "TDS Concessional Code";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        TDSConcessionlCode.init();
        TDSConcessionlCode.Validate("Vendor No.", VendorNo);
        TDSConcessionlCode.Validate(Section, TDSSection);
        TDSConcessionlCode.Validate("Concessional Code", ConcessionalCode);
        TDSConcessionlCode.Validate("Certificate No.", LibraryUtility.GenerateRandomCode(TDSConcessionlCode.FieldNo("Certificate No."),
        Database::"TDS Concessional Code"));
        TDSConcessionlCode.Insert(true);
    end;

    procedure CreateAssesseeCode(var AssesseeCode: Record "Assessee Code")
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        AssesseeCode.Init();
        AssesseeCode.Validate(Code, LibraryUtility.GenerateRandomCode(AssesseeCode.FIELDNO(Code), DATABASE::"Assessee Code"));
        AssesseeCode.Validate(Description, AssesseeCode.Code);
        AssesseeCode.Insert(true);
    end;

    local procedure CreateDeductorCategory(): Code[20]
    var
        DeductorCategory: Record "Deductor Category";
        LibraryUtility: Codeunit "Library - Utility";
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

    procedure CreateTANNo(): Code[10]
    var
        TANNos: Record "TAN Nos.";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        TANNos.Init();
        TANNos.Validate(Code, LibraryUtility.GenerateRandomCode(TANNos.FIELDNO(Code), DATABASE::"TAN Nos."));
        TANNos.Validate(Description, TANNos.Code);
        TANNos.Insert(true);
        exit(TANNos.Code);
    end;

    procedure CreateTDSSection(var TDSSection: Record "TDS Section")
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        TDSSection.Init();
        TDSSection.Validate(Code,
          COPYSTR(
            LibraryUtility.GenerateRandomCode(TDSSection.FIELDNO(Code), DATABASE::"TDS Section"),
            1, LibraryUtility.GetFieldLength(DATABASE::"TDS Section", TDSSection.FIELDNO(Code))));
        TDSSection.Validate(Description, TDSSection.Code);
        TDSSection.Validate(ecode,
          COPYSTR(
            LibraryUtility.GenerateRandomCode(TDSSection.FIELDNO(Code), DATABASE::"TDS Section"),
            1, LibraryUtility.GetFieldLength(DATABASE::"TDS Section", TDSSection.FIELDNO(Code))));
        TDSSection.Insert(true);
    end;

    procedure AttachSectionWithVendor(Section: Code[10]; VendorNo: Code[20]; DefaultSection: Boolean;
    SurchargeOverLook: Boolean; ThresholdOverlook: Boolean)
    var
        AllowedSections: Record "Allowed Sections";
    begin
        AllowedSections.Init();
        AllowedSections.Validate("Vendor No", VendorNo);
        AllowedSections.Validate("TDS Section", Section);
        AllowedSections.Validate("Default Section", DefaultSection);
        AllowedSections.Validate("Surcharge Overlook", SurchargeOverLook);
        AllowedSections.Validate("Threshold Overlook", ThresholdOverlook);
        AllowedSections.Insert(true);
    end;

    procedure CreateTDSPostingSetup(var TDSPostingSetup: Record "TDS Posting Setup"; TDSSection: Code[20])
    var
        LibraryERM: Codeunit "Library - ERM";
    begin
        TDSPostingSetup.Init();
        TDSPostingSetup.Validate("TDS Section", TDSSection);
        TDSPostingSetup.Validate("Effective Date", WorkDate());
        TDSPostingSetup.Validate("TDS Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
        TDSPostingSetup.Insert(true);
    end;

    procedure CreateTDSPostingSetupWithSection(var TDSPostingSetup: Record "TDS Posting Setup"; var TDSSection: Record "TDS Section")
    begin
        CreateTDSSection(TDSSection);
        CreateTDSPostingSetup(TDSPostingSetup, TDSSection.Code);
    end;

    procedure CreateNatureOfRemittance(var NatureOfRemittance: Record "TDS Nature of Remittance")
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        NatureOfRemittance.Init();
        NatureOfRemittance.Validate(Code,
          LibraryUtility.GenerateRandomCode(NatureOfRemittance.FIELDNO(Code), DATABASE::"TDS Nature of Remittance"));
        NatureOfRemittance.Validate(Description, LibraryUtility.GenerateRandomText(50));
        NatureOfRemittance.Insert(true);
    end;

    procedure CreateActApplicable(var ActApplicable: Record "Act Applicable")
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        ActApplicable.Init();
        ActApplicable.Validate(Code,
          LibraryUtility.GenerateRandomCode(ActApplicable.FIELDNO(Code), DATABASE::"Act Applicable"));
        ActApplicable.Validate(Description, LibraryUtility.GenerateRandomText(50));
        ActApplicable.Insert(true);
    end;

    procedure AttachSectionWithForeignVendor(Section: Code[10]; VendorNo: Code[20]; DefaultSection: Boolean;
    SurchargeOverLook: Boolean; ThresholdOverlook: Boolean; NonResidentPayments: Boolean; NatureofRemittance: Code[10]; ActApplicable: Code[10])
    var
        AllowedSections: Record "Allowed Sections";
    begin
        AllowedSections.SetRange("Vendor No", VendorNo);
        AllowedSections.SetRange("TDS Section", Section);
        if AllowedSections.FindFirst() then begin
            AllowedSections.Validate("Non Resident Payments", true);
            AllowedSections.Validate("Nature of Remittance", NatureofRemittance);
            AllowedSections.Validate("Act Applicable", ActApplicable);
            AllowedSections.Modify(true);
        end;
    end;

    procedure CreateForeignVendorWithPANNoandWithoutConcessional(var Vendor: Record Vendor)
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        NatureOfRemittance: Record "TDS Nature of Remittance";
        ActApplicable: Record "Act Applicable";
        CountryRegion: Record "Country/Region";
        Currency: Record Currency;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        CurrencyCode: Code[10];
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup.Code, GenProductPostingGroup.Code);
        CreateNatureOfRemittance(NatureOfRemittance);
        CreateActApplicable(ActApplicable);
        LibraryERM.CreateCountryRegion(CountryRegion);
        vendor.Validate("Currency Code", CreateCurrencyCode());
        Vendor.Validate("P.A.N. No.",
          LibraryUtility.GenerateRandomCode(Vendor.FIELDNO("P.A.N. No."), DATABASE::Vendor));
        Vendor.Validate("Country/Region Code", CountryRegion.Code);
        Vendor.Modify(true);
    end;

    procedure CreateForeignVendorWithPANNoandWithConcessional(var Vendor: Record Vendor)
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        NatureOfRemittance: Record "TDS Nature of Remittance";
        ConcessionalCode: Record "Concessional Code";
        ActApplicable: Record "Act Applicable";
        CountryRegion: Record "Country/Region";
        Currency: Record Currency;
        TDSSection: Record "TDS Section";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        CurrencyCode: Code[10];
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup.Code, GenProductPostingGroup.Code);
        CreateNatureOfRemittance(NatureOfRemittance);
        CreateActApplicable(ActApplicable);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Vendor.Validate("P.A.N. No.",
          LibraryUtility.GenerateRandomCode(Vendor.FIELDNO("P.A.N. No."), DATABASE::Vendor));
        CreateConcessionalCode(ConcessionalCode);
        AttachConcessionalCodeWithVendor(ConcessionalCode.Code, Vendor."No.", TDSSection.Code);
        Vendor.Validate("Country/Region Code", CountryRegion.Code);
        Vendor.Modify(true);
    end;

    procedure CreateForeignVendorWithoutPANNoandWithoutConcessional(var Vendor: Record Vendor)
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        NatureOfRemittance: Record "TDS Nature of Remittance";
        ActApplicable: Record "Act Applicable";
        CountryRegion: Record "Country/Region";
        Currency: Record Currency;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        CurrencyCode: Code[10];
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup.Code, GenProductPostingGroup.Code);
        CreateNatureOfRemittance(NatureOfRemittance);
        CreateActApplicable(ActApplicable);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Vendor.Validate("P.A.N. Status", Vendor."P.A.N. Status"::PANAPPLIED);
        Vendor.Validate("P.A.N. Reference No.", LibraryRandom.RandText(10));
        Vendor.Validate("Country/Region Code", CountryRegion.Code);
        Vendor.Modify(true);
    end;

    procedure CreateForeignVendorWithoutPANNoandWithConcessional(var Vendor: Record Vendor)
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        NatureOfRemittance: Record "TDS Nature of Remittance";
        ActApplicable: Record "Act Applicable";
        CountryRegion: Record "Country/Region";
        ConcessionalCode: Record "Concessional Code";
        Currency: Record Currency;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        CurrencyCode: Code[10];
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup.Code, GenProductPostingGroup.Code);
        CreateNatureOfRemittance(NatureOfRemittance);
        CreateActApplicable(ActApplicable);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Vendor.Validate("P.A.N. Status", Vendor."P.A.N. Status"::PANAPPLIED);
        Vendor.Validate("P.A.N. Reference No.", LibraryRandom.RandText(10));
        CreateConcessionalCode(ConcessionalCode);
        Vendor.Validate("Country/Region Code", CountryRegion.Code);
        Vendor.Modify(true);
    end;

    procedure CreateConcessionalCode(var ConCode: Record "Concessional Code")
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        ConCode.Init();
        ConCode.Validate(
          Code,
          COPYSTR(
            LibraryUtility.GenerateRandomCode(ConCode.FIELDNO(Code), DATABASE::"TDS Concessional Code"),
            1, LibraryUtility.GetFieldLength(DATABASE::"TDS Concessional Code", ConCode.FIELDNO(Code))));
        ConCode.Validate(Description, ConCode.Code);
        ConCode.Insert(true)
    end;

    procedure CreateMinistry(var Ministry: Record Ministry)
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        Ministry.Init();
        Ministry.Validate(Code, LibraryUtility.GenerateRandomCode(Ministry.FIELDNO(Code), DATABASE::Ministry));
        Ministry.Validate(Name, LibraryUtility.GenerateRandomText(150));
        Ministry.Insert(true);
    end;

    procedure AttachConcessionalCodeWithVendor(ConcessionalCode: Code[10]; VendorNo: Code[20]; TDSSection: Code[10])
    var
        ConcessionlCode: Record "TDS Concessional Code";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        ConcessionlCode.Init();
        ConcessionlCode.Validate("Vendor No.", VendorNo);
        ConcessionlCode.Validate(Section, TDSSection);
        ConcessionlCode.Validate("Concessional Code", ConcessionalCode);
        ConcessionlCode.Validate("Certificate No.", LibraryUtility.GenerateRandomCode(ConcessionlCode.FieldNo("Certificate No."),
        Database::"TDS Concessional Code"));
        ConcessionlCode.Insert(true);
    end;

    procedure CreateGSTTDSSetup(var Vendor: Record Vendor; var TDSPostingSetup: Record "TDS Posting Setup"; var ConcessionalCode: Record "Concessional Code")
    var
        AssesseeCode: Record "Assessee Code";
        TDSSection: Record "TDS Section";
    begin
        CreateCommonSetup(AssesseeCode, ConcessionalCode);
        CreateTDSPostingSetupWithSection(TDSPostingSetup, TDSSection);
        CreateGSTTDSVendor(Vendor, AssesseeCode.Code, TDSSection.Code);
        AttachConcessionalWithVendor(Vendor."No.", ConcessionalCode.Code, TDSSection.Code);
    end;

    local procedure CreateGSTTDSVendor(var Vendor: Record Vendor; AssesseeCode: Code[10]; TDSSection: Code[10]);
    var
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        CreateZeroVATPostingSetup(VATPostingSetup);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate("Assessee Code", AssesseeCode);
        UpdateTDSSectionOnVendor(Vendor."No.", TDSSection);
        Vendor.Modify(true);
    end;

    procedure CreateTDSPostingSetupWithDifferentEffectiveDate(TDSSectionCode: Code[20]; EffectiveDate: Date; AccountNo: code[20])
    var
        TDSPostingSetup: Record "TDS Posting Setup";
    begin
        TDSPostingSetup.Init();
        TDSPostingSetup.Validate("TDS Section", TDSSectionCode);
        TDSPostingSetup.Validate("Effective Date", EffectiveDate);
        TDSPostingSetup.Validate("TDS Account", AccountNo);
        TDSPostingSetup.Insert(true);
    end;

    procedure CreateTDSPostingSetupForMultipleSection(var TDSPostingSetup: Record "TDS Posting Setup"; var TDSSection: Record "TDS Section")
    begin
        CreateTDSSection(TDSSection);
        CreateTDSPostingSetup(TDSPostingSetup, TDSSection.Code);
    end;

    procedure InsertCompanyInformationDetails()
    var
        DeductorCategory: Record "Deductor Category";
        CompanyInformation: Record "Company Information";
        TANNo: Record "TAN Nos.";
        GSTRegistrationNo: Record "GST Registration Nos.";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        CompanyInformation.GET();
        if CompanyInformation."GST Registration No." = '' then begin
            if not GSTRegistrationNo.IsEmpty then
                CompanyInformation.Validate("P.A.N. No.", CopyStr(GSTRegistrationNo.Code, 3, 10))
            else
                CompanyInformation.Validate("P.A.N. No.", LibraryUtility.GenerateRandomCode(CompanyInformation.FieldNo("P.A.N. No."), Database::"Company Information"));
        end else
            CompanyInformation.Validate("P.A.N. No.", CopyStr(CompanyInformation."GST Registration No.", 3, 10));
        CompanyInformation.Validate("Deductor Category", CreateDeductorCategory());
        CompanyInformation.Validate("PAO Code", LibraryUtility.GenerateRandomText(20));
        CompanyInformation.Validate("PAO Registration No.", LibraryUtility.GenerateRandomText(7));
        CompanyInformation.Validate("DDO Code", LibraryUtility.GenerateRandomText(7));
        CompanyInformation.Validate("DDO Registration No.", LibraryUtility.GenerateRandomText(7));
        CompanyInformation.Validate("T.A.N. No.", CreateTANNo());
        if CompanyInformation."State Code" = '' then
            CompanyInformation.Validate("State Code", CreateStateCode());
        CompanyInformation.Validate("T.A.N. No.", CreateTANNo());
        CompanyInformation.Modify(true);
    end;

    local procedure CreateStateCode(): Code[10]
    var
        State: Record State;
        LibraryUtility: Codeunit "Library - Random";
    begin
        if State.FindFirst() then
            exit(State.Code)
        else begin
            State.Init();
            State.Validate(Code, LibraryUtility.RandText(2));
            State.Validate(Description, State.Code);
            State.Insert(true);
            exit(State.Code);
        end;
    end;

    procedure RemoveTANOnCompInfo()
    var
        CompInfo: Record "Company Information";
    begin
        CompInfo.get();
        CompInfo.Validate("T.A.N. No.", '');
        CompInfo.Modify(true);
    end;

    procedure CreateTDSAccountingPeriod();
    var
        TaxType: Record "Tax Type";
        TDSSetup: Record "TDS Setup";
        Date: Record Date;
        CreateTaxAccountingPeriod: Report "Create Tax Accounting Period";
        PeriodLength: DateFormula;
    begin
        if not TDSSetup.Get() then
            exit;
        TaxType.Get(TDSSetup."Tax Type");
        Date.SetRange("Period Type", Date."Period Type"::Year);
        Date.SetRange("Period No.", DATE2DMY(WORKDATE(), 3));
        date.FindFirst();

        CLEAR(CreateTaxAccountingPeriod);
        Evaluate(PeriodLength, '<1M>');
        CreateTaxAccountingPeriod.InitializeRequest(12, PeriodLength, Date."Period Start", TaxType."Accounting Period");
        CreateTaxAccountingPeriod.HideConfirmationDialog(true);
        CreateTaxAccountingPeriod.USEREQUESTPAGE(FALSE);
        CreateTaxAccountingPeriod.RUN();
    end;

    local procedure IsTaxAccountingPeriodEmpty(): Boolean
    var
        TDSSetup: Record "TDS Setup";
        TaxType: Record "Tax Type";
        TaxAccountingPeriod: Record "Tax Accounting Period";
    begin
        if not TDSSetup.Get() then
            exit;
        TDSSetup.TestField("Tax Type");

        TaxType.Get(TDSSetup."Tax Type");

        TaxAccountingPeriod.SetRange("Tax Type Code", TaxType."Accounting Period");
        TaxAccountingPeriod.SetFilter("Starting Date", '<=%1', WorkDate());
        TaxAccountingPeriod.SetFilter("Ending Date", '>=%1', WorkDate());
        if TaxAccountingPeriod.IsEmpty then
            exit(true);
    end;

    procedure VerifyGLEntryCount(DocumentNo: Code[20]; ExpectedCount: Integer)
    var
        DummyGLEntry: Record "G/L Entry";
        Assert: Codeunit Assert;
    begin
        DummyGLEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(DummyGLEntry, ExpectedCount);
    end;

    procedure VerifyGLEntryWithTDS(DocumentNo: Code[20]; TDSAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, TDSAccountNo);
        GLEntry.TestField(Amount, GetTDSAmount(DocumentNo));
    end;

    procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; TDSAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", TDSAccountNo);
        GLEntry.FindSet();
    end;

    procedure GetTDSAmount(DocumentNo: Code[20]): Decimal
    var
        TDSEntry: Record "TDS Entry";
        TDSAmount: Decimal;
    begin
        TDSEntry.SetRange("Document No.", DocumentNo);
        if TDSEntry.FindSet() then
            repeat
                TDSAmount += TDSEntry."Total TDS Including SHE CESS";
            until TDSEntry.Next() = 0;
        exit(-TDSAmount);
    end;

    procedure VerifyTDSEntry(DocumentNo: Code[20]; DocumentType: Option; TDSBaseAmount: Decimal)
    var
        TDSEntry: Record "TDS Entry";
        Assert: Codeunit Assert;
        AmountErr: Label '%1 is incorrect in %2.', Comment = '%1 and %2 = TDS% and TDS field Caption';
    begin
        TDSEntry.SetRange("Document Type", DocumentType);
        TDSEntry.SetRange("Document No.", DocumentNo);
        TDSEntry.FindFirst();
        Assert.AreNearlyEqual(
          TDSBaseAmount, TDSEntry."TDS Base Amount", 0,
           STRSUBSTNO(AmountErr, TDSBaseAmount, TDSEntry.FieldCaption("TDS Base Amount")));
    end;

    procedure AttachWorktaxInTDSPostingSetup(var TDSPostingSetup: Record "TDS Posting Setup"; TDSSection: Code[20])
    var
        LibraryERM: Codeunit "Library - ERM";
    begin
        TDSPostingSetup.SetRange("TDS Section", TDSSection);
        TDSPostingSetup.Validate("Work Tax Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
        TDSPostingSetup.Modify(true);
    end;

    procedure VerifyGLEntryWithWorkTax(DocumentNo: Code[20]; WorktaxAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, WorktaxAccountNo);
        GLEntry.TestField(Amount, GetTDSAmountWithWorktax(DocumentNo));
    end;

    procedure GetTDSAmountWithWorktax(DocumentNo: Code[20]): Decimal
    var
        TDSEntry: Record "TDS Entry";
        TDSAmount: Decimal;
    begin
        TDSEntry.SetRange("Document No.", DocumentNo);
        if TDSEntry.FindSet() then
            repeat
                TDSAmount += TDSEntry."Work Tax Amount";
            until TDSEntry.Next() = 0;
        exit(-TDSAmount);
    end;

    procedure GetTDSRoundingPrecision(): Decimal
    var
        TaxComponent: Record "Tax Component";
        TDSSetup: Record "TDS Setup";
        TDSRoundingPrecision: Decimal;
    begin
        if not TDSSetup.Get() then
            exit;
        TDSSetup.TestField("Tax Type");
        TaxComponent.SetRange("Tax Type", TDSSetup."Tax Type");
        TaxComponent.SetRange(Name, TDSSetup."Tax Type");
        TaxComponent.FindFirst();
        if TaxComponent."Rounding Precision" <> 0 then
            TDSRoundingPrecision := TaxComponent."Rounding Precision"
        else
            TDSRoundingPrecision := 1;
        exit(TDSRoundingPrecision);
    end;

    procedure RoundTDSAmount(TDSAmount: Decimal): Decimal
    var
        TaxComponent: Record "Tax Component";
        TDSSetup: Record "TDS Setup";
        TDSRoundingPrecision: Decimal;
        TDSRoundingDirection: Text[1];
    begin
        if not TDSSetup.Get() then
            exit;
        TDSSetup.TestField("Tax Type");
        TaxComponent.SetRange("Tax Type", TDSSetup."Tax Type");
        TaxComponent.SetRange(Name, TDSSetup."Tax Type");
        TaxComponent.FindFirst();

        case TaxComponent.Direction of
            TaxComponent.Direction::Nearest:
                TDSRoundingPrecision := '=';
            TaxComponent.Direction::Up:
                TDSRoundingPrecision := '>';
            TaxComponent.Direction::Down:
                TDSRoundingPrecision := '<';
        end;
        if TaxComponent."Rounding Precision" <> 0 then
            TDSRoundingPrecision := TaxComponent."Rounding Precision"
        else
            TDSRoundingPrecision := 1;
        exit(Round(TDSAmount, TDSRoundingPrecision, TDSRoundingDirection));
    end;

    procedure FindStartDateOnAccountingPeriod(): Date
    var
        TDSSetup: Record "TDS Setup";
        TaxType: record "Tax Type";
        AccountingPeriod: Record "Tax Accounting Period";
    begin
        TDSSetup.Get();
        TaxType.Get(TDSSetup."Tax Type");
        AccountingPeriod.SetCurrentKey("Tax Type Code");
        AccountingPeriod.SetRange("Tax Type Code", TaxType."Accounting Period");
        AccountingPeriod.SetRange(Closed, false);
        AccountingPeriod.Ascending(true);
        if AccountingPeriod.FindFirst() then
            exit(AccountingPeriod."Starting Date");
    end;

    procedure CreateCurrencyCode(): Code[10]
    var
        Currency: Record Currency;
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), 100, LibraryRandom.RandDecInDecimalRange(70, 80, 2));
        exit(Currency.Code);
    end;

    procedure CreateZeroVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, 0);
    end;
}