codeunit 131305 "Library - ERM Country Data"
{
    // Procedures to create demo data present in W1 but missing in countries


    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";

    procedure InitializeCountry()
    begin
        exit;
    end;

    procedure CreateVATData()
    begin
        CreateVATSetup;
    end;

    procedure GetVATCalculationType(): Integer
    var
        DummyVATPostingSetup: Record "VAT Posting Setup";
    begin
        exit(DummyVATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    [Scope('OnPrem')]
    procedure GetReportSelectionsUsagePurchaseQuote(): Integer
    var
        ReportSelections: Record "Report Selections";
    begin
        exit(ReportSelections.Usage::"P.Quote");
    end;

    [Scope('OnPrem')]
    procedure GetReportSelectionsUsageSalesQuote(): Integer
    var
        ReportSelections: Record "Report Selections";
    begin
        exit(ReportSelections.Usage::"S.Quote");
    end;

    procedure SetupCostAccounting()
    begin
        exit;
    end;

    procedure SetupReportSelections()
    var
        DummyReportSelections: Record "Report Selections";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"S.Quote", REPORT::"Standard Sales - Quote");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"S.Invoice", REPORT::"Standard Sales - Invoice");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"S.Cr.Memo", REPORT::"Standard Sales - Credit Memo");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"SM.Invoice", REPORT::"Service - Invoice");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"SM.Credit Memo", REPORT::"Service - Credit Memo");
    end;

    procedure UpdateAccountInCustomerPostingGroup()
    begin
        exit;
    end;

    procedure UpdateAccountInVendorPostingGroups()
    begin
        exit;
    end;

    procedure UpdateAccountsInServiceContractAccountGroups()
    begin
        exit;
    end;

    procedure UpdateAccountInServiceCosts()
    begin
        exit;
    end;

    procedure UpdateCalendarSetup()
    begin
        exit;
    end;

    procedure UpdateGeneralPostingSetup()
    begin
        exit;
    end;

    procedure UpdateInventoryPostingSetup()
    begin
        exit;
    end;

    procedure UpdateGenJournalTemplate()
    begin
        exit;
    end;

    procedure UpdateGeneralLedgerSetup()
    begin
        DisableFullGSTOnPrepayment;
    end;

    procedure UpdatePrepaymentAccounts()
    begin
        exit;
    end;

    procedure UpdatePurchasesPayablesSetup()
    begin
        exit;
    end;

    procedure UpdateSalesReceivablesSetup()
    begin
        exit;
    end;

    procedure UpdateGenProdPostingGroup()
    begin
        exit;
    end;

    procedure CreateGeneralPostingSetupData()
    begin
        exit;
    end;

    procedure CreateUnitsOfMeasure()
    begin
        exit;
    end;

    procedure CreateTransportMethodTableData()
    begin
        exit;
    end;

    procedure UpdateFAPostingGroup()
    begin
        exit;
    end;

    procedure UpdateFAPostingType()
    begin
        exit;
    end;

    procedure UpdateFAJnlTemplateName()
    begin
        exit;
    end;

    procedure CreateNewFiscalYear()
    begin
        exit;
    end;

    procedure UpdateVATPostingSetup()
    begin
        exit;
    end;

    procedure DisableActivateChequeNoOnGeneralLedgerSetup()
    begin
        exit;
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    procedure RemoveBlankGenJournalTemplate()
    begin
        exit;
    end;

    procedure UpdateLocalPostingSetup()
    begin
        exit;
    end;

    procedure UpdateLocalData()
    begin
        exit;
    end;

    procedure CompanyInfoSetVATRegistrationNo()
    var
        CompanyInformation: Record "Company Information";
        LibraryERM: Codeunit "Library - ERM";
    begin
        CompanyInformation.Get();
        CompanyInformation."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code");
        CompanyInformation.Modify();
    end;

    procedure AmountOnBankAccountLedgerEntriesPage(var BankAccountLedgerEntries: TestPage "Bank Account Ledger Entries"): Decimal
    var
        EntryRemainingAmount: Decimal;
    begin
        Evaluate(EntryRemainingAmount, BankAccountLedgerEntries.Amount.Value);
        exit(EntryRemainingAmount);
    end;

    procedure InsertRecordsToProtectedTables()
    begin
    end;

    local procedure CreateVATSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryRandom: Codeunit "Library - Random";
    begin
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        if VATPostingSetup.Count = 0 then begin
            LibraryERM.CreateVATPostingSetupWithAccounts(
              VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandInt(15));
            VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", CreateGLAccount);
            VATPostingSetup.Modify(true);
        end;
    end;

    local procedure DisableFullGSTOnPrepayment()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        with GLSetup do begin
            Get;
            Validate("Full GST on Prepayment", false);
            Modify(true);
        end;
    end;
}

