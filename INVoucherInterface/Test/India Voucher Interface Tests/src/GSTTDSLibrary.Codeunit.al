codeunit 18997 "GST TDS Library"
{
    trigger OnRun()
    begin

    end;

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

    procedure CreateZeroVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, 0);
    end;
}
