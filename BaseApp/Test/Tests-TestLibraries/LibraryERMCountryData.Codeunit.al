codeunit 131305 "Library - ERM Country Data"
{
    // Procedures to create demo data present in W1 but missing in countries


    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";

    procedure InitializeCountry()
    begin
        exit;
    end;

    procedure CreateVATData()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '');
        if VATPostingSetup.FindSet then
            repeat
                if (VATPostingSetup."Sales VAT Account" = '') or (VATPostingSetup."Purchase VAT Account" = '') then begin
                    VATPostingSetup.Validate("Sales VAT Account", CreateGLAccount);
                    VATPostingSetup.Validate("Purchase VAT Account", CreateGLAccount);
                    VATPostingSetup.Modify(true);
                end;
            until VATPostingSetup.Next = 0;
    end;

    procedure GetVATCalculationType(): Enum "Tax Calculation Type"
    begin
        exit("Tax Calculation Type"::"Normal VAT");
    end;

    [Scope('OnPrem')]
    procedure GetReportSelectionsUsagePurchaseQuote(): Integer
    var
        ReportSelections: Record "Report Selections";
    begin
        exit(ReportSelections.Usage::"P.Quote".AsInteger());
    end;

    [Scope('OnPrem')]
    procedure GetReportSelectionsUsageSalesQuote(): Integer
    var
        ReportSelections: Record "Report Selections";
    begin
        exit(ReportSelections.Usage::"S.Quote".AsInteger());
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
        exit;
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
    var
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeriesCode: Code[20];
        Modified: Boolean;
    begin
        // Registration No in Sales Invoice
        NoSeriesCode := LibraryUtility.GetGlobalNoSeriesCode;
        SalesSetup.Get();

        if SalesSetup."Reference Nos." <> NoSeriesCode then begin
            SalesSetup.Validate("Reference Nos.", NoSeriesCode);
            Modified := true;
        end;

        if SalesSetup."Invoice No." then begin
            SalesSetup."Invoice No." := false;
            Modified := true;
        end;
        if SalesSetup.Date then begin
            SalesSetup.Date := false;
            Modified := true;
        end;
        if SalesSetup."Customer No." then begin
            SalesSetup."Customer No." := false;
            Modified := true;
        end;
        if SalesSetup."Default Number" <> '' then begin
            SalesSetup."Default Number" := '';
            Modified := true;
        end;

        if Modified then
            SalesSetup.Modify(true);
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

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;
}

