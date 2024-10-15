codeunit 131305 "Library - ERM Country Data"
{
    // Procedures to create demo data present in W1 but missing in countries


    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";

    [Scope('OnPrem')]
    procedure InitializeCountry()
    begin
        exit;
    end;

    procedure CreateVATData()
    begin
        CreateVATSetup;
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
        UpdateAccountsInGeneralPostingSetup;
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
        DisableWHTAndGSTInGeneralLedgerSetup;
    end;

    procedure UpdatePrepaymentAccounts()
    begin
        UpdateVATPostingSetupOnPrepAccount();
        UpdateGenProdPostingSetupOnPrepAccount();
    end;

    procedure UpdatePurchasesPayablesSetup()
    begin
        UpdatePurchaseReceivableSetupData;
    end;

    procedure UpdateSalesReceivablesSetup()
    begin
        UpdateSalesReceivableSetupData;
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
        UpdateZeroVATPercentInVATPostingSetup;
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
        UpdateZeroWHTPercentInWHTPostingSetup;
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

    local procedure CreateVATSetup()
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        if VATPostingSetup.Count = 0 then begin
            VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '');
            VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '');
            VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            VATPostingSetup.SetFilter("VAT %", '>0');
            if VATPostingSetup.Count > 1 then begin
                VATPostingSetup.FindFirst();
                VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
                VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo);
                VATPostingSetup.Modify(true);
            end;
        end;
    end;

    local procedure DisableWHTAndGSTInGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Enable WHT", false);
        GeneralLedgerSetup.Validate("Full GST on Prepayment", false);
        GeneralLedgerSetup.Validate("Enable GST (Australia)", false);
        GeneralLedgerSetup.Validate("GST Report", false);
        GeneralLedgerSetup.Validate("Adjustment Mandatory", false);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateAccountsInGeneralPostingSetup()
    var
        NormalGeneralPostingSetup: Record "General Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGeneralPostingSetupInvtFull(NormalGeneralPostingSetup);
        with GeneralPostingSetup do
            if FindSet() then
                repeat
                    if "Sales Pmt. Disc. Credit Acc." = '' then
                        "Sales Pmt. Disc. Credit Acc." := NormalGeneralPostingSetup."Sales Pmt. Disc. Credit Acc.";  // Using assignment to avoid error.
                    if GeneralPostingSetup."Purch. Pmt. Disc. Debit Acc." = '' then
                        "Purch. Pmt. Disc. Debit Acc." := NormalGeneralPostingSetup."Purch. Pmt. Disc. Debit Acc.";  // Using assignment to avoid error.
                    if "Sales Account" = '' then
                        Validate("Sales Account", NormalGeneralPostingSetup."Sales Account");
                    if "Inventory Adjmt. Account" = '' then
                        Validate("Inventory Adjmt. Account", NormalGeneralPostingSetup."Inventory Adjmt. Account");
                    if "Direct Cost Applied Account" = '' then
                        Validate("Direct Cost Applied Account", NormalGeneralPostingSetup."Direct Cost Applied Account");
                    if "Overhead Applied Account" = '' then
                        Validate("Overhead Applied Account", NormalGeneralPostingSetup."Overhead Applied Account");
                    if "Purch. Prepayments Account" = '' then
                        Validate("Purch. Prepayments Account", NormalGeneralPostingSetup."Purch. Prepayments Account");
                    if "Sales Prepayments Account" = '' then
                        Validate("Sales Prepayments Account", NormalGeneralPostingSetup."Sales Prepayments Account");
                    Modify(true);
                until Next = 0;
    end;

    local procedure UpdateZeroVATPercentInVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", '');
        VATPostingSetup.FindSet();
        repeat
            VATPostingSetup.Validate("VAT %", 0);
            VATPostingSetup.Modify(true);
        until VATPostingSetup.Next() = 0;
    end;

    local procedure UpdateSalesReceivableSetupData()
    var
        SalesReceivableSetup: Record "Sales & Receivables Setup";
        ReasonCode: Record "Reason Code";
    begin
        SalesReceivableSetup.Get();
        if not ReasonCode.FindFirst() then
            LibraryERM.CreateReasonCode(ReasonCode);
        SalesReceivableSetup.Validate("Payment Discount Reason Code", ReasonCode.Code);
        SalesReceivableSetup.Validate("Default Cancel Reason Code", ReasonCode.Code);
        SalesReceivableSetup.Validate("Invoice Rounding", false);
        SalesReceivableSetup.Modify(true);
    end;

    local procedure UpdatePurchaseReceivableSetupData()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        ReasonCode: Record "Reason Code";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Invoice Rounding", false);
        if not ReasonCode.FindFirst() then
            LibraryERM.CreateReasonCode(ReasonCode);
        PurchasesPayablesSetup.Validate("Default Cancel Reason Code", ReasonCode.Code);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateZeroWHTPercentInWHTPostingSetup()
    var
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        if WHTPostingSetup.FindSet() then
            repeat
                WHTPostingSetup.Validate("WHT %", 0);
                WHTPostingSetup.Validate("WHT Minimum Invoice Amount", 0);
                WHTPostingSetup.Validate("Realized WHT Type", WHTPostingSetup."Realized WHT Type"::" ");
                WHTPostingSetup.Modify(true);
            until WHTPostingSetup.Next() = 0;
    end;
}

