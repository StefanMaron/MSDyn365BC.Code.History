codeunit 143020 "Library - Tax"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";

    [Scope('OnPrem')]
    procedure CloseVATControlReportLines(var VATControlReportHeader: Record "VAT Control Report Header")
    begin
        VATControlReportHeader.CloseLines;
    end;

    [Scope('OnPrem')]
    procedure CreateCommodity(var Commodity: Record Commodity)
    begin
        with Commodity do begin
            Init;
            Code := LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::Commodity);
            Description := Code;
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateCommoditySetup(var CommoditySetup: Record "Commodity Setup"; CommodityCode: Code[10]; ValidFrom: Date; ValidTo: Date; LimitAmount: Decimal)
    begin
        with CommoditySetup do begin
            Init;
            "Commodity Code" := CommodityCode;
            "Valid From" := ValidFrom;
            "Valid To" := ValidTo;
            "Commodity Limit Amount LCY" := LimitAmount;
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateDefaultVATControlReportSections()
    var
        VATControlReportSection: Record "VAT Control Report Section";
    begin
        if not VATControlReportSection.IsEmpty then
            exit;

        CreateVATControlReportSection(
          VATControlReportSection, 'A1', VATControlReportSection."Group By"::"Document No.", '');
        CreateVATControlReportSection(
          VATControlReportSection, 'A2', VATControlReportSection."Group By"::"External Document No.", '');
        CreateVATControlReportSection(
          VATControlReportSection, 'A3', VATControlReportSection."Group By"::"Document No.", '');
        CreateVATControlReportSection(
          VATControlReportSection, 'A5', VATControlReportSection."Group By"::"Section Code", '');
        CreateVATControlReportSection(
          VATControlReportSection, 'A4', VATControlReportSection."Group By"::"Document No.", 'A5');
        CreateVATControlReportSection(
          VATControlReportSection, 'B1', VATControlReportSection."Group By"::"External Document No.", '');
        CreateVATControlReportSection(
          VATControlReportSection, 'B3', VATControlReportSection."Group By"::"Section Code", '');
        CreateVATControlReportSection(
          VATControlReportSection, 'B2', VATControlReportSection."Group By"::"External Document No.", 'B3');
    end;

    [Scope('OnPrem')]
    procedure CreateElectronicallyGovernSetup()
    var
        ElectronicallyGovernSetup: Record "Electronically Govern. Setup";
    begin
        ElectronicallyGovernSetup.Reset;
        if not ElectronicallyGovernSetup.FindFirst then begin
            ElectronicallyGovernSetup.Init;
            ElectronicallyGovernSetup.Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTariffNumber(var TariffNumber: Record "Tariff Number")
    begin
        with TariffNumber do begin
            Init;
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::"Tariff Number");
            Description := "No.";
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateVATAttributeCode(var VATAttributeCode: Record "VAT Attribute Code"; VATStmtTempName: Code[10])
    begin
        VATAttributeCode.Init;
        VATAttributeCode."VAT Statement Template Name" := VATStmtTempName;
        VATAttributeCode.Code :=
          LibraryUtility.GenerateRandomCode(VATAttributeCode.FieldNo(Code), DATABASE::"VAT Attribute Code");
        VATAttributeCode.Description :=
          StrSubstNo('%1 %2', VATAttributeCode."VAT Statement Template Name", VATAttributeCode.Code);
        VATAttributeCode.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVATClause(var VATClause: Record "VAT Clause")
    begin
        VATClause.Init;
        VATClause.Code := LibraryUtility.GenerateRandomCode(VATClause.FieldNo(Code), DATABASE::"VAT Clause");
        VATClause.Validate(Description, LibraryUtility.GenerateRandomText(20));
        VATClause.Validate("Description 2", LibraryUtility.GenerateRandomText(50));
        VATClause.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVATControlReport(var VATControlReportHeader: Record "VAT Control Report Header")
    begin
        with VATControlReportHeader do begin
            Init;
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateVATControlReportWithPeriod(var VATControlReportHeader: Record "VAT Control Report Header"; PeriodNo: Integer; PeriodYear: Integer)
    begin
        with VATControlReportHeader do begin
            CreateVATControlReport(VATControlReportHeader);

            Validate("Period No.", PeriodNo);
            Validate(Year, PeriodYear);
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateVATControlReportSection(var VATControlReportSection: Record "VAT Control Report Section"; VATControlReportSectionCode: Code[20]; GroupBy: Option; SectionCode: Code[20])
    begin
        with VATControlReportSection do begin
            Init;
            Code := VATControlReportSectionCode;
            Description := VATControlReportSectionCode;
            "Group By" := GroupBy;
            "Simplified Tax Doc. Sect. Code" := SectionCode;
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateVIESDeclarationHeader(var VIESDeclarationHeader: Record "VIES Declaration Header")
    begin
        VIESDeclarationHeader.Init;
        VIESDeclarationHeader.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateNonDeductibleVATSetup(var NonDeductibleVATSetup: Record "Non Deductible VAT Setup"; VATBusPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20]; FromDate: Date; NonDeductibleVATPer: Decimal)
    begin
        NonDeductibleVATSetup.Init;
        NonDeductibleVATSetup.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        NonDeductibleVATSetup.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        NonDeductibleVATSetup.Validate("From Date", FromDate);
        NonDeductibleVATSetup.Validate("Non Deductible VAT %", NonDeductibleVATPer);
        NonDeductibleVATSetup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateStatReportingSetup()
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
    begin
        StatReportingSetup.Reset;
        if not StatReportingSetup.FindFirst then begin
            StatReportingSetup.Init;
            StatReportingSetup.Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCompanyOfficialsNo(): Code[20]
    var
        CompanyOfficials: Record "Company Officials";
    begin
        FindCompanyOfficials(CompanyOfficials);
        exit(CompanyOfficials."No.");
    end;

    [Scope('OnPrem')]
    procedure GetInvalidVATRegistrationNo(): Text[20]
    begin
        exit('CZ11111111');
    end;

    [Scope('OnPrem')]
    procedure GetNotPublicBankAccountNo(): Code[30]
    begin
        exit('14-123123123/0100');
    end;

    [Scope('OnPrem')]
    procedure GetPublicBankAccountNo(): Code[30]
    begin
        exit('86-5211550267/0100');
    end;

    [Scope('OnPrem')]
    procedure GetValidVATRegistrationNo(): Text[20]
    begin
        exit('CZ25820826'); // Webcom a.s.
    end;

    [Scope('OnPrem')]
    procedure GetVATPeriodStartingDate(): Date
    var
        VATPeriod: Record "VAT Period";
        VATEntry: Record "VAT Entry";
    begin
        FindVATPeriod(VATPeriod);
        FindVATEntry(VATEntry);

        if VATPeriod."Starting Date" > VATEntry."Posting Date" then
            exit(VATPeriod."Starting Date");
        exit(VATEntry."Posting Date");
    end;

    [Scope('OnPrem')]
    procedure ExportVATControlReport(VATControlReportHeader: Record "VAT Control Report Header"): Text
    var
        FileManagement: Codeunit "File Management";
        ClientTempFileName: Text;
        ClientFileName: Text;
    begin
        ClientTempFileName := FileManagement.ClientTempFileName('');
        ClientFileName := VATControlReportHeader.Export();
        exit(FileManagement.CombinePath(FileManagement.GetDirectoryName(ClientTempFileName), ClientFileName));
    end;

    [Scope('OnPrem')]
    procedure ExportVIESDeclaration(VIESDeclarationHeader: Record "VIES Declaration Header"): Text
    var
        VIESDeclarationLine: Record "VIES Declaration Line";
        TempVIESDeclarationLine: Record "VIES Declaration Line" temporary;
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        VIESDeclaration: XMLport "VIES Declaration";
        OutputStream: OutStream;
    begin
        TempVIESDeclarationLine.DeleteAll;
        TempVIESDeclarationLine.Reset;
        VIESDeclarationLine.SetRange("VIES Declaration No.", VIESDeclarationHeader."No.");
        if VIESDeclarationLine.FindSet then
            repeat
                TempVIESDeclarationLine := VIESDeclarationLine;
                TempVIESDeclarationLine.Insert;
            until VIESDeclarationLine.Next = 0;

        TempBlob.CreateOutStream(OutputStream);
        VIESDeclaration.SetHeader(VIESDeclarationHeader);
        VIESDeclaration.SetLines(TempVIESDeclarationLine);
        VIESDeclaration.SetDestination(OutputStream);
        VIESDeclaration.Export;

        exit(FileManagement.BLOBExport(TempBlob, 'Default.xml', false));
    end;

    [Scope('OnPrem')]
    procedure FindCompanyOfficials(var CompanyOfficials: Record "Company Officials")
    begin
        CompanyOfficials.Reset;
        CompanyOfficials.FindFirst;
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry")
    begin
        VATEntry.Reset;
        VATEntry.SetRange(Closed, false);
        VATEntry.FindFirst;
    end;

    [Scope('OnPrem')]
    procedure FindVATPeriod(var VATPeriod: Record "VAT Period")
    begin
        VATPeriod.Reset;
        VATPeriod.SetRange(Closed, false);
        VATPeriod.FindFirst;
    end;

    [Scope('OnPrem')]
    procedure FindVATStatementTemplate(var VATStatementTemplate: Record "VAT Statement Template")
    begin
        VATStatementTemplate.Reset;
        VATStatementTemplate.FindFirst;
    end;

    [Scope('OnPrem')]
    procedure PrintDocumentationForVAT(ShowRequestPage: Boolean)
    begin
        Commit;
        REPORT.Run(REPORT::"Documentation for VAT", ShowRequestPage, false);
    end;

    [Scope('OnPrem')]
    procedure PrintVATStatement(var VATStatementLine: Record "VAT Statement Line"; ShowRequestPage: Boolean)
    begin
        REPORT.Run(REPORT::"VAT Statement", ShowRequestPage, false, VATStatementLine);
    end;

    [Scope('OnPrem')]
    procedure PrintTestVATControlReport(var VATControlReportHeader: Record "VAT Control Report Header")
    begin
        Commit;
        VATControlReportHeader.PrintTestReport;
    end;

    [Scope('OnPrem')]
    procedure PrintTestVIESDeclaration(var VIESDeclarationHeader: Record "VIES Declaration Header")
    begin
        Commit;
        VIESDeclarationHeader.PrintTestReport;
    end;

    [Scope('OnPrem')]
    procedure ReleaseVATControlReport(var VATControlReportHeader: Record "VAT Control Report Header")
    begin
        CODEUNIT.Run(CODEUNIT::"Release VAT Control Report", VATControlReportHeader);
    end;

    [Scope('OnPrem')]
    procedure ReleaseVIESDeclaration(var VIESDeclarationHeader: Record "VIES Declaration Header")
    begin
        CODEUNIT.Run(CODEUNIT::"Release VIES Declaration", VIESDeclarationHeader);
    end;

    [Scope('OnPrem')]
    procedure ReopenVATPeriod(StartingDate: Date)
    var
        VATPeriod: Record "VAT Period";
    begin
        VATPeriod.Reset;
        VATPeriod.Get(StartingDate);
        VATPeriod.Validate(Closed, false);
        VATPeriod.Modify;
    end;

    [Scope('OnPrem')]
    procedure ReopenVIESDeclaration(var VIESDeclarationHeader: Record "VIES Declaration Header")
    var
        ReleaseVIESDeclaration: Codeunit "Release VIES Declaration";
    begin
        ReleaseVIESDeclaration.Reopen(VIESDeclarationHeader);
    end;

    [Scope('OnPrem')]
    procedure RoundVAT(VATAmount: Decimal): Decimal
    var
        VATAmountLine: Record "VAT Amount Line";
    begin
        exit(VATAmountLine.RoundVAT(VATAmount));
    end;

    [Scope('OnPrem')]
    procedure RunCreateVATPeriod()
    begin
        Commit;
        REPORT.Run(REPORT::"Create VAT Period", true, false);
    end;

    [Scope('OnPrem')]
    procedure RunExportVATStatement(StmtTempName: Code[10]; StmtName: Code[10])
    var
        VATStatementName: Record "VAT Statement Name";
        ExportVATStatement: Page "Export VAT Statement";
    begin
        VATStatementName.SetRange("Statement Template Name", StmtTempName);
        VATStatementName.SetRange(Name, StmtName);
        VATStatementName.FindFirst;

        ExportVATStatement.SetRecord(VATStatementName);
        ExportVATStatement.SetTableView(VATStatementName);
        ExportVATStatement.EnableExportToServerFile();
        ExportVATStatement.Run();
    end;

    [Scope('OnPrem')]
    procedure RunGetCorrectionVIESDeclarationLines(var VIESDeclarationHeader: Record "VIES Declaration Header")
    var
        VIESDeclarationLines: Page "VIES Declaration Lines";
    begin
        VIESDeclarationLines.SetToDeclaration(VIESDeclarationHeader);
        VIESDeclarationLines.LookupMode := true;
        if VIESDeclarationLines.RunModal = ACTION::LookupOK then
            VIESDeclarationLines.CopyLineToDeclaration;
    end;

    [Scope('OnPrem')]
    procedure RunMassUncertaintyPayerGet()
    begin
        Commit;
        REPORT.Run(REPORT::"Mass Uncertainty Payer Get");
    end;

    [Scope('OnPrem')]
    procedure RunSuggestVIESDeclarationLines(var VIESDeclarationHeader: Record "VIES Declaration Header")
    begin
        Commit;
        VIESDeclarationHeader.SetRecFilter;
        REPORT.RunModal(REPORT::"Suggest VIES Declaration Lines", true, false, VIESDeclarationHeader);
    end;

    [Scope('OnPrem')]
    procedure RunUncertaintyVATPayment(var Vendor: Record Vendor)
    var
        UncPayerMgt: Codeunit "Unc. Payer Mgt.";
    begin
        UncPayerMgt.ImportUncPayerStatusForVendor(Vendor);
    end;

    [Scope('OnPrem')]
    procedure SelectVATStatementName(var VATStatementName: Record "VAT Statement Name")
    begin
        VATStatementName.SetRange("Statement Template Name", SelectVATStatementTemplate);

        if not VATStatementName.FindFirst then
            LibraryERM.CreateVATStatementName(VATStatementName, SelectVATStatementTemplate);
    end;

    [Scope('OnPrem')]
    procedure SelectVATStatementTemplate(): Code[10]
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        VATStatementTemplate.SetRange("Page ID", PAGE::"VAT Statement");

        if not VATStatementTemplate.FindFirst then
            LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);

        exit(VATStatementTemplate.Name);
    end;

    [Scope('OnPrem')]
    procedure SetAttributeCode(var VATStatementLine: Record "VAT Statement Line"; AttributeCode: Code[20])
    begin
        VATStatementLine."Attribute Code" := AttributeCode;
        VATStatementLine.Modify;
    end;

    [Scope('OnPrem')]
    procedure SetCompanyType(CompanyType: Option)
    var
        CoInfo: Record "Company Information";
    begin
        CoInfo.Get;
        CoInfo."Company Type" := CompanyType;
        CoInfo.Modify;
    end;

    [Scope('OnPrem')]
    procedure SetVATControlReportInformation()
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
    begin
        StatReportingSetup.Get;
        StatReportingSetup."Tax Office Number" := '461';
        StatReportingSetup."Tax Office Region Number" := '3003';
        StatReportingSetup."VAT Stat. Auth.Employee No." := GetCompanyOfficialsNo;
        StatReportingSetup."VAT Stat. Filled by Empl. No." := GetCompanyOfficialsNo;
        StatReportingSetup."VAT Statement Country Name" := 'CESKO';
        StatReportingSetup."VAT Control Report Nos." := LibraryERM.CreateNoSeriesCode;
        StatReportingSetup."Simplified Tax Document Limit" := 10000;
        StatReportingSetup."Data Box ID" := 'ad57cf71';
        StatReportingSetup."VAT Control Report E-mail" := 'test@test.cz';
        StatReportingSetup.Modify;
    end;

    [Scope('OnPrem')]
    procedure SetVATStatementInformation()
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
    begin
        StatReportingSetup.Get;
        StatReportingSetup."VAT Statement Country Name" := 'CESKO';
        StatReportingSetup."VAT Stat. Auth.Employee No." := GetCompanyOfficialsNo;
        StatReportingSetup."VAT Stat. Filled by Empl. No." := GetCompanyOfficialsNo;
        StatReportingSetup.Modify;
    end;

    [Scope('OnPrem')]
    procedure SetVIESStatementInformation()
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
    begin
        StatReportingSetup.Get;
        StatReportingSetup."Tax Office Number" := '461';
        StatReportingSetup."Tax Office Region Number" := '3003';
        StatReportingSetup."VIES Declaration Nos." := LibraryERM.CreateNoSeriesCode;
        StatReportingSetup."Taxpayer Type" := StatReportingSetup."Taxpayer Type"::Corporation;
        StatReportingSetup."Tax Payer Status" := StatReportingSetup."Tax Payer Status"::Payer;
        StatReportingSetup."VIES Number of Lines" := 20;
        StatReportingSetup."VIES Declaration Report No." := REPORT::"VIES Declaration";
        StatReportingSetup."VIES Decl. Exp. Obj. Type" := StatReportingSetup."VIES Decl. Exp. Obj. Type"::Report;
        StatReportingSetup."VIES Decl. Exp. Obj. No." := REPORT::"VIES Declaration Export";
        StatReportingSetup.Modify;
    end;

    [Scope('OnPrem')]
    procedure SetUncertaintyPayerWebService()
    var
        ElectronicallyGovernSetup: Record "Electronically Govern. Setup";
    begin
        ElectronicallyGovernSetup.Get;
        ElectronicallyGovernSetup.UncertaintyPayerWebService :=
          'http://adisrws.mfcr.cz/adistc/axis2/services/rozhraniCRPDPH.rozhraniCRPDPHSOAP';
        ElectronicallyGovernSetup.Modify;
    end;

    [Scope('OnPrem')]
    procedure SetUseVATDate(UseVATDate: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get;
        GeneralLedgerSetup.Validate("Use VAT Date", UseVATDate);
        GeneralLedgerSetup.Modify;
    end;

    [Scope('OnPrem')]
    procedure SetXMLFormat(var VATStatementTemplate: Record "VAT Statement Template"; XMLFormat: Option)
    begin
        VATStatementTemplate."XML Format" := XMLFormat;
        VATStatementTemplate.Modify;
    end;

    [Scope('OnPrem')]
    procedure SuggestVATControlReportLines(var VATControlReportHeader: Record "VAT Control Report Header")
    begin
        VATControlReportHeader.SuggestLines;
    end;
}

