codeunit 131305 "Library - ERM Country Data"
{
    // Procedures to create demo data present in W1 but missing in countries


    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryInventory: Codeunit "Library - Inventory";

    procedure InitializeCountry()
    begin
        exit;
    end;

    procedure CreateVATData()
    begin
        exit;
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
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"S.Order", REPORT::"Standard Sales - Order Conf.");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"S.Cr.Memo", REPORT::"Standard Sales - Credit Memo");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"SM.Invoice", REPORT::"Service - Invoice");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"SM.Credit Memo", REPORT::"Service - Credit Memo");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"P.Quote", Report::"Purchase - Quote");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"P.Invoice", Report::"Purchase - Invoice");
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
        CreateUserSetup; // NAVCZ
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
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        UpdateVATPostingSetupOnPrepAccount();
        UpdateGenProdPostingSetupOnPrepAccount();
    end;

    procedure UpdatePurchasesPayablesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // NAVCZ
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Allow Document Deletion Before" := CalcDate('<CY>', WorkDate());
        PurchasesPayablesSetup.Modify();
        // NAVCZ
    end;

    procedure UpdateSalesReceivablesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ReasonCode: Record "Reason Code";
    begin
        // NAVCZ
        LibraryERM.CreateReasonCode(ReasonCode);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Allow Document Deletion Before" := CalcDate('<CY>', WorkDate());
        SalesReceivablesSetup.Modify();
        // NAVCZ
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
    var
        FAPostingTypeSetup: Record "FA Posting Type Setup";
    begin
        FAPostingTypeSetup.ModifyAll("Include in Gain/Loss Calc.", true);
    end;

    procedure UpdateFAJnlTemplateName()
    begin
        exit;
    end;

    procedure UpdateJournalTemplMandatory(Mandatory: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Journal Templ. Name Mandatory", Mandatory);
        GeneralLedgerSetup.Modify(true);
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

    local procedure UpdateGenProdPostingSetupOnPrepAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        GeneralPostingSetup.SetFilter("Sales Prepayments Account", '<>%1', '');
        if GeneralPostingSetup.FindSet() then
            repeat
                GLAccount.Get(GeneralPostingSetup."Sales Prepayments Account");
                if GLAccount."Gen. Prod. Posting Group" = '' then begin
                    GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
                    GLAccount.Modify(true);
                end;
            until GeneralPostingSetup.Next() = 0;
        GeneralPostingSetup.Reset();
        GeneralPostingSetup.SetFilter("Purch. Prepayments Account", '<>%1', '');
        if GeneralPostingSetup.FindSet() then
            repeat
                GLAccount.Get(GeneralPostingSetup."Purch. Prepayments Account");
                if GLAccount."Gen. Prod. Posting Group" = '' then begin
                    GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
                    GLAccount.Modify(true);
                end;
            until GeneralPostingSetup.Next() = 0;
    end;

    local procedure UpdateVATPostingSetupOnPrepAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        GeneralPostingSetup.SetFilter("Sales Prepayments Account", '<>%1', '');
        if GeneralPostingSetup.FindSet() then
            repeat
                GLAccount.Get(GeneralPostingSetup."Sales Prepayments Account");
                if GLAccount."VAT Prod. Posting Group" = '' then begin
                    GenProdPostingGroup.Get(GeneralPostingSetup."Gen. Prod. Posting Group");
                    GLAccount.Validate("VAT Prod. Posting Group", GenProdPostingGroup."Def. VAT Prod. Posting Group");
                    GLAccount.Modify(true);
                end;
            until GeneralPostingSetup.Next() = 0;
        GeneralPostingSetup.Reset();
        GeneralPostingSetup.SetFilter("Purch. Prepayments Account", '<>%1', '');
        if GeneralPostingSetup.FindSet() then
            repeat
                GLAccount.Get(GeneralPostingSetup."Purch. Prepayments Account");
                if GLAccount."VAT Prod. Posting Group" = '' then begin
                    GenProdPostingGroup.Get(GeneralPostingSetup."Gen. Prod. Posting Group");
                    GLAccount.Validate("VAT Prod. Posting Group", GenProdPostingGroup."Def. VAT Prod. Posting Group");
                    GLAccount.Modify(true);
                end;
            until GeneralPostingSetup.Next() = 0;
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
        if BankAccountLedgerEntries.Amount.Visible() then
            EntryRemainingAmount := BankAccountLedgerEntries.Amount.AsDecimal()
        else
            if BankAccountLedgerEntries."Credit Amount".AsDecimal <> 0 then
                EntryRemainingAmount := -BankAccountLedgerEntries."Credit Amount".AsDecimal()
            else
                EntryRemainingAmount := BankAccountLedgerEntries."Debit Amount".AsDecimal();
        exit(EntryRemainingAmount);
    end;

    procedure InsertRecordsToProtectedTables()
    begin
    end;

    local procedure CreateUserSetup()
    var
        UserSetup: Record "User Setup";
    begin
        // NAVCZ
        if not UserSetup.Get(UserId) then begin
            UserSetup.Init();
            UserSetup."User ID" := UserId;
            UserSetup.Insert();
        end;
        UserSetup."Time Sheet Admin." := true;
        UserSetup.Modify(true);
    end;
}

