codeunit 18194 "GST TCS Library"
{

    trigger OnRun()
    begin

    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";

    procedure CreateGSTTCSSetup(
        var Customer: Record Customer;
        var TCSPostingSetup: Record "TCS Posting Setup";
        var ConcessionalCode: Record "Concessional Code")
    var
        AssesseeCode: Record "Assessee Code";
        TCSNatureOfCollection: Record "TCS Nature Of Collection";
    begin
        CreateGSTTCSCommmonSetup(AssesseeCode, ConcessionalCode);
        CreateTCSPostingSetupWithNOC(TCSPostingSetup, TCSNatureOfCollection);
        CreateGSTTCSCustomer(Customer, AssesseeCode.Code, TCSNatureOfCollection.Code);
        AttachConcessionalWithCustomer(Customer."No.", ConcessionalCode.Code, TCSNatureOfCollection.Code);
    end;

    procedure CreateTCSPostingSetupWithNOC(
        var TCSPostingSetup: Record "TCS Posting Setup";
        var TCSNOC: Record "TCS Nature Of Collection")
    begin
        CreateTCSNatureOfCollection(TCSNOC);
        CreateTCSPostingSetup(TCSPostingSetup, TCSNOC.Code);
    end;

    procedure CreateTCSNatureOfCollection(var TCSNatureOfCollection: Record "TCS Nature Of Collection")
    begin
        TCSNatureOfCollection.Init();
        TCSNatureOfCollection.Validate(Code, LibraryUtility.GenerateRandomCode(TCSNatureOfCollection.FieldNo(Code), DATABASE::"TCS Nature Of Collection"));
        TCSNatureOfCollection.Validate(Description, TCSNatureOfCollection.Code);
        TCSNatureOfCollection.Insert(true);
    end;

    procedure CreateTCSPostingSetup(
        var TCSPostingSetup: Record "TCS Posting Setup";
        TCSNatureOfCollectionCode: Code[20])
    begin
        TCSPostingSetup.Init();
        TCSPostingSetup.Validate("TCS Nature of Collection", TCSNatureOfCollectionCode);
        TCSPostingSetup.Validate("Effective Date", WorkDate());
        TCSPostingSetup.Validate("TCS Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        TCSPostingSetup.Insert(true);
    end;

    procedure AttachConcessionalWithCustomer(
        CustomerNo: Code[20];
        ConcessionalCode: Code[10];
        TCSNatureOfCollection: Code[10])
    var
        CustomerConcessionalCode: Record "Customer Concessional Code";
    begin
        CustomerConcessionalCode.Init();
        CustomerConcessionalCode.Validate("Customer No.", CustomerNo);
        CustomerConcessionalCode.Validate("TCS Nature of Collection", TCSNatureOfCollection);
        CustomerConcessionalCode.Validate("Concessional Code", ConcessionalCode);
        CustomerConcessionalCode.Validate("Concessional Form No.", LibraryUtility.GenerateRandomCode(CustomerConcessionalCode.FieldNo("Concessional Form No."), Database::"Customer Concessional Code"));
        CustomerConcessionalCode.Insert(true);
    end;

    procedure CreateTCANNo(): Code[10]
    var
        TCANNo: Record "T.C.A.N. No.";
    begin
        TCANNo.Init();
        TCANNo.Validate(Code, LibraryUtility.GenerateRandomCode(TCANNo.FieldNo(Code), DATABASE::"T.C.A.N. No."));
        TCANNo.Validate(Description, TCANNo.Code);
        TCANNo.Insert(true);
        exit(TCANNo.Code);
    end;

    procedure CreateConcessionalCode(var ConcessionalCode: Record "Concessional Code")
    begin
        ConcessionalCode.Init();
        ConcessionalCode.Validate(Code, LibraryUtility.GenerateRandomCode(ConcessionalCode.FieldNo(Code), DATABASE::"Concessional Code"));
        ConcessionalCode.Validate(Description, ConcessionalCode.Code);
        ConcessionalCode.Insert(true);
    end;

    procedure CreateAssesseeCode(var AssesseeCode: Record "Assessee Code")
    begin
        AssesseeCode.Init();
        AssesseeCode.Validate(Code, LibraryUtility.GenerateRandomCode(AssesseeCode.FieldNo(Code), Database::"Assessee Code"));
        AssesseeCode.Validate(Description, AssesseeCode.Code);
        AssesseeCode.Insert(true);
    end;

    procedure CreateDeductorCategory(): Code[20]
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

    procedure CreateTCSAccountingPeriod()
    var
        TaxType: Record "Tax Type";
        TCSSetup: Record "TCS Setup";
        Date: Record Date;
        CreateTaxAccountingPeriod: Report "Create Tax Accounting Period";
        PeriodLength: DateFormula;
    begin
        if not TCSSetup.Get() then
            exit;
        TaxType.Get(TCSSetup."Tax Type");

        Date.SetRange("Period Type", Date."Period Type"::Year);
        Date.SetRange("Period No.", Date2DMY(WorkDate(), 3));
        if Date.FindFirst() then;

        Clear(CreateTaxAccountingPeriod);
        Evaluate(PeriodLength, '<1M>');
        CreateTaxAccountingPeriod.InitializeRequest(12, PeriodLength, Date."Period Start", TaxType."Accounting Period");
        CreateTaxAccountingPeriod.HideConfirmationDialog(true);
        CreateTaxAccountingPeriod.UseRequestPage(false);
        CreateTaxAccountingPeriod.Run();
    end;

    procedure UpdateCustomerWithNOCWithOutConcessionalGST(
        var Customer: Record Customer;
        ThresholdOverlook: Boolean;
        SurchargeOverlook: Boolean)
    var
        CustomerConcessionalCode: Record "Customer Concessional Code";
    begin
        UpdateNOCOnCustomer(Customer."No.", ThresholdOverlook, SurchargeOverlook);
        CustomerConcessionalCode.SetRange("Customer No.", Customer."No.");
        CustomerConcessionalCode.DeleteAll(true);
    end;

    local procedure CreateGSTTCSCustomer(var Customer: Record Customer; AssesseeCode: Code[10]; TCSNOC: Code[10])
    begin
        Customer.Validate("VAT Bus. Posting Group", GetVATBusPostingWithNOVAT());
        Customer.Validate("Assessee Code", AssesseeCode);
        UpdateNOCOnCustomer(Customer."No.", TCSNOC);
        Customer.Modify(true);
    end;

    local procedure UpdateNOCOnCustomer(CustomerNo: Code[20]; NOCType: Code[10])
    var
        AllowedNOC: Record "Allowed Noc";
    begin
        AllowedNOC.Init();
        AllowedNOC.Validate("Customer No.", CustomerNo);
        AllowedNOC.Validate("TCS Nature of Collection", NOCType);
        AllowedNOC.Validate("Default Noc", true);
        AllowedNOC.Insert(true);
    end;

    local procedure GetVATBusPostingWithNOVAT(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetFilter("VAT %", '%1', 0);
        if VATPostingSetup.FindFirst() then
            exit(VATPostingSetup."VAT Bus. Posting Group");
    end;

    local procedure CreateGSTTCSCommmonSetup(
        var AssesseeCode: Record "Assessee Code";
        var ConcessionalCode: Record "Concessional Code")
    var
        CompanyInfo: Record "Company Information";
    begin
        if IsTaxAccountingPeriodEmpty() then
            CreateTCSAccountingPeriod();
        CompanyInfo.Get();
        CompanyInfo.Validate("Circle No.", LibraryUtility.GenerateRandomText(30));
        CompanyInfo.Validate("Ward No.", LibraryUtility.GenerateRandomText(30));
        CompanyInfo.Validate("Assessing Officer", LibraryUtility.GenerateRandomText(30));
        CompanyInfo.Validate("Deductor Category", CreateDeductorCategory());
        CompanyInfo.Validate("T.C.A.N. No.", CreateTCANNo());
        CompanyInfo.Modify(true);
        CreateConcessionalCode(ConcessionalCode);
        CreateAssesseeCode(AssesseeCode);
    end;

    local procedure IsTaxAccountingPeriodEmpty(): Boolean
    var
        TCSSetup: Record "TCS Setup";
        TaxType: Record "Tax Type";
        TaxAccountingPeriod: Record "Tax Accounting Period";
    begin
        if not TCSSetup.Get() then
            exit;
        TCSSetup.TestField("Tax Type");

        TaxType.Get(TCSSetup."Tax Type");

        TaxAccountingPeriod.SetRange("Tax Type Code", TaxType."Accounting Period");
        TaxAccountingPeriod.SetFilter("Starting Date", '<=%1', WorkDate());
        TaxAccountingPeriod.SetFilter("Ending Date", '>=%1', WorkDate());
        if TaxAccountingPeriod.IsEmpty then
            exit(true);
    end;

    local procedure UpdateNOCOnCustomer(CustomerNo: Code[20]; ThresholdOverLook: Boolean; SurchargeOverlook: Boolean)
    var
        AllowedNOC: Record "Allowed NOC";
    begin
        AllowedNOC.SetRange("Customer No.", CustomerNo);
        AllowedNOC.FindFirst();
        AllowedNOC.Validate("Threshold Overlook", ThresholdOverlook);
        AllowedNOC.Validate("Surcharge Overlook", SurchargeOverlook);
        AllowedNOC.Modify(true);
    end;
}