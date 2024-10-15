#if not CLEAN20
codeunit 143020 "Library - Tax"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.';
    ObsoleteTag = '20.0';

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure CreateDefaultVATControlReportSections()
    begin
        exit;
    end;

    [Scope('OnPrem')]
    [Obsolete('The Electronically Govern. Setup table is obsoleted.', '20.0')]
    procedure CreateElectronicallyGovernSetup()
    begin
        exit;
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
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
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure CreateVATClause(var VATClause: Record "VAT Clause")
    begin
        VATClause.Init();
        VATClause.Code := LibraryUtility.GenerateRandomCode(VATClause.FieldNo(Code), DATABASE::"VAT Clause");
        VATClause.Validate(Description, LibraryUtility.GenerateRandomText(20));
        VATClause.Validate("Description 2", LibraryUtility.GenerateRandomText(50));
        VATClause.Insert(true);
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure CreateStatReportingSetup()
#if not CLEAN18
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
#endif
    begin
#if not CLEAN18
        StatReportingSetup.Reset();
        if not StatReportingSetup.FindFirst() then begin
            StatReportingSetup.Init();
            StatReportingSetup.Insert();
        end;
#else
        exit;
#endif
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure GetCompanyOfficialsNo(): Code[20]
    begin
        exit;
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure GetInvalidVATRegistrationNo(): Text[20]
    begin
        exit('CZ11111111');
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure GetNotPublicBankAccountNo(): Code[30]
    begin
        exit('14-123123123/0100');
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure GetPublicBankAccountNo(): Code[30]
    begin
        exit('86-5211550267/0100');
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure GetValidVATRegistrationNo(): Text[20]
    begin
        exit('CZ25820826'); // Webcom a.s.
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure GetVATPeriodStartingDate(): Date
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry);
        exit(VATEntry."Posting Date");
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry")
    begin
        VATEntry.Reset();
        VATEntry.SetRange(Closed, false);
        VATEntry.FindFirst();
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure FindVATStatementTemplate(var VATStatementTemplate: Record "VAT Statement Template")
    begin
        VATStatementTemplate.Reset();
        VATStatementTemplate.FindFirst();
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure PrintDocumentationForVAT(ShowRequestPage: Boolean)
    begin
        exit;
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure PrintVATStatement(var VATStatementLine: Record "VAT Statement Line"; ShowRequestPage: Boolean)
    begin
        REPORT.Run(REPORT::"VAT Statement", ShowRequestPage, false, VATStatementLine);
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure ReopenVATPeriod(StartingDate: Date)
    begin
        exit;
    end;

    [Scope('OnPrem')]
    [Obsolete('Unused function.', '20.0')]
    procedure RoundVAT(VATAmount: Decimal): Decimal
    var
        VATAmountLine: Record "VAT Amount Line";
    begin
        exit(VATAmountLine.RoundVAT(VATAmount));
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure RunCreateVATPeriod()
    begin
        exit;
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure RunExportVATStatement(StmtTempName: Code[10]; StmtName: Code[10])
    begin
        exit;
    end;

    [Scope('OnPrem')]
    [Obsolete('The "Mass Uncertainty Payer Get" report is obsoleted.', '20.0')]
    procedure RunMassUncertaintyPayerGet()
    begin
        exit;
    end;

    [Scope('OnPrem')]
    [Obsolete('The "Unc. Payer Mgt." codeunit is obsoleted.', '20.0')]
    procedure RunUncertaintyVATPayment(var Vendor: Record Vendor)
    begin
        exit;
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure SelectVATStatementName(var VATStatementName: Record "VAT Statement Name")
    begin
        VATStatementName.SetRange("Statement Template Name", SelectVATStatementTemplate);

        if not VATStatementName.FindFirst() then
            LibraryERM.CreateVATStatementName(VATStatementName, SelectVATStatementTemplate);
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure SelectVATStatementTemplate(): Code[10]
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        VATStatementTemplate.SetRange("Page ID", PAGE::"VAT Statement");

        if not VATStatementTemplate.FindFirst() then
            LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);

        exit(VATStatementTemplate.Name);
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure SetAttributeCode(var VATStatementLine: Record "VAT Statement Line"; AttributeCode: Code[20])
    begin
        exit;
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure SetCompanyType(CompanyType: Option)
    begin
        exit;
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure SetVATControlReportInformation()
    begin
        exit;
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure SetVATStatementInformation()
    begin
        exit;
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure SetVIESStatementInformation()
    begin
        exit;
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure SetUncertaintyPayerWebService()
    begin
        exit;
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to "Library - Tax CZL" codeunit of "Core Localization Pack for Czech Tests" app.', '20.0')]
    procedure SetUseVATDate(UseVATDate: Boolean)
#if not CLEAN19
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
#endif
    begin
#if not CLEAN19
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Use VAT Date", UseVATDate);
        GeneralLedgerSetup.Modify();
#else
        exit;
#endif
    end;
}
#endif
