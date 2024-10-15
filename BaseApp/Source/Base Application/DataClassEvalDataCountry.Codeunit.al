codeunit 1752 "Data Class. Eval. Data Country"
{

    trigger OnRun()
    begin
    end;

    var
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";

    procedure ClassifyCountrySpecificTables()
    begin
        ClassifyEmployee;
        ClassifyEmployeeRelative;
        ClassifyEmployeeQualification;
        ClassifyVATReportHeader;
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register Dim. Value Comb.");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"G/L Correspondence");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"G/L Correspondence Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Gen. Journal Line Archive");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"VAT Ledger");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"VAT Ledger Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"VAT Ledger Connection");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"CD No. Format");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"CD No. Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"CD No. Information");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"CD Tracking Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Bank Directory");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"VAT Ledger Line CD No.");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"VAT Ledger Line Tariff No.");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Document Signature");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Posted Document Signature");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Company Address");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::KBK);
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::OKATO);
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Default Signature Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Taxpayer Document Type");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Bank Account Details");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Invt. Document Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Invt. Receipt Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Invt. Receipt Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Invt. Document Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Invt. Shipment Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Invt. Shipment Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Item Document Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Item Receipt Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Item Receipt Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Item Document Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Item Shipment Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Item Shipment Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Direct Transfer Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Direct Transfer Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"FA Document Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Posted FA Doc. Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Posted FA Doc. Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Depreciation Code");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Item/FA Precious Metal");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Precious Metal");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Depreciation Group");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"FA Document Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"FA Comment");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Posted FA Comment");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Vendor Agreement");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Customer Agreement");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Agreement Group");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Letter of Attorney Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Letter of Attorney Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"FA Charge");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Invent. Act Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Invent. Act Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Payment Order Code");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Excel Template");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Assessed Tax Allowance");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Assessed Tax Code");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"VAT Allocation Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Default VAT Allocation Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Journal Posting Preview Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Excel Template Sheet");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Excel Template Section");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"G/L Corr. Analysis View");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"G/L Corr. Analysis View Filter");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"G/L Corr. Analysis View Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"VAT Entry Type");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register Line Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register Template");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register G/L Corr. Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register Term");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register Term Formula");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register Section");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register Accumulation");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register G/L Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register CV Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register FA Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register Item Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register FE Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register Dim. Comb.");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Cause of Absence");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Sales Header Archive");
        ClassifyCountrySpecificTablesPart2;
        ClassifyCountrySpecificTablesPart3;
        OnAfterClassifyCountrySpecificTables();
    end;

    local procedure ClassifyCountrySpecificTablesPart2()
    begin
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register Dim. Def. Value");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register Dim. Filter");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register Dim. Corr. Filter");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register Norm Jurisdiction");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register Norm Group");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register Norm Detail");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Register Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Gen. Template Profile");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Gen. Term Profile");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Reg. Norm Template Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Reg. Norm Term");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Reg. Norm Term Formula");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Reg. Norm Accumulation");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Reg. Norm Dim. Filter");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Reg. G/L Corr. Dim. Filter");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Difference");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Diff. Posting Group");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Diff. Register");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Diff. Journal Template");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Diff. Journal Batch");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Diff. Journal Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Diff. Ledger Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Calc. Section");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Calc. Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Calc. Selection Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Calc. Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Calc. Term");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Calc. Term Formula");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Calc. Dim. Filter");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Calc. Accumulation");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Calc. G/L Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Calc. Item Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Calc. FA Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Calc. G/L Corr. Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Calc. Dim. Corr. Filter");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Diff. Group");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Tax Diff. Corr. Dim. Filter");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Person Document");
    end;

    local procedure ClassifyCountrySpecificTablesPart3()
    begin
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Key Including In Report");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Including In Report");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Statutory Report");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Statutory Report Group");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Statutory Report Table");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Stat. Report Table Row");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Stat. Report Table Column");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Scalable Table Row");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Table Individual Requisite");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Requisite Condition Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Stat. Report Excel Sheet");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Statutory Report Data Header");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Statutory Report Data Value");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Stat. Report Data Change Log");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Export Log Entry");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Statutory Report Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"XML Element Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Page Indication XML Element");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"XML Element Expression Line");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Format Version");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Acc. Schedule Extension");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Stat. Report Table Mapping");
    end;

    local procedure ClassifyEmployeeRelative()
    var
        DummyEmployeeRelative: Record "Employee Relative";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Employee Relative";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeRelative.FieldNo("Relative's Employee No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployeeRelative.FieldNo("Phone No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployeeRelative.FieldNo("Birth Date"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployeeRelative.FieldNo("Last Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployeeRelative.FieldNo("Middle Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployeeRelative.FieldNo("First Name"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeRelative.FieldNo("Relative Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeRelative.FieldNo("Line No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeRelative.FieldNo("Employee No."));
    end;

    local procedure ClassifyEmployeeQualification()
    var
        DummyEmployeeQualification: Record "Employee Qualification";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Employee Qualification";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo("Expiration Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo("Employee Status"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo("Course Grade"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo(Cost));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo("Institution/Company"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo(Description));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo(Type));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo("To Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo("From Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo("Qualification Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo("Line No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyEmployeeQualification.FieldNo("Employee No."));
    end;

    local procedure ClassifyEmployee()
    var
        DummyEmployee: Record Employee;
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::Employee;
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo(Image));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo(IBAN));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Bank Account No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Bank Branch No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Company E-Mail"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Fax No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo(Pager));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo(Extension));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyEmployee.FieldNo("Termination Date"));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyEmployee.FieldNo("Inactive Date"));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyEmployee.FieldNo(Status));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyEmployee.FieldNo("Employment Date"));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyEmployee.FieldNo(Gender));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyEmployee.FieldNo("Union Membership No."));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyEmployee.FieldNo("Union Code"));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyEmployee.FieldNo("Social Security No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Birth Date"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("E-Mail"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Mobile Phone No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Phone No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo(County));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo(City));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo(Address));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Search Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Last Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("Middle Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyEmployee.FieldNo("First Name"));
    end;

    local procedure ClassifyVATReportHeader()
    var
        DummyVATReportHeader: Record "VAT Report Header";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"VAT Report Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVATReportHeader.FieldNo("Submitted By"));
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"VAT Return Period");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClassifyCountrySpecificTables()
    begin
    end;
}
