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
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        if InventoryPostingSetup.FindSet then
            repeat
                if InventoryPostingSetup."Inventory Account (Interim)" = '' then
                    InventoryPostingSetup.Validate("Inventory Account (Interim)", CreateGLAccount);
                InventoryPostingSetup.Modify();
            until InventoryPostingSetup.Next = 0;
    end;

    procedure UpdateGenJournalTemplate()
    begin
        exit;
    end;

    procedure UpdateGeneralLedgerSetup()
    begin
        DisableAdjustForPmtDiscInGLSetup;
    end;

    procedure UpdatePrepaymentAccounts()
    begin
        UpdateVATPostingSetupOnPrepAccount();
        UpdateGenProdPostingSetupOnPrepAccount();
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
        UpdateAccountsInFAPostingGroup;
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
        DeleteExtraGeneralJournalTemplate;
    end;

    local procedure UpdateAccountsInFAPostingGroup()
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        if FAPostingGroup.FindSet then
            repeat
                if FAPostingGroup."Losses Acc. on Disposal" = '' then begin
                    FAPostingGroup.Validate("Losses Acc. on Disposal", CreateGLAccount);
                    FAPostingGroup.Modify(true);
                end;
            until FAPostingGroup.Next = 0;
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
        if BankAccountLedgerEntries."Credit Amount".AsDEcimal <> 0 then
            EntryRemainingAmount := -BankAccountLedgerEntries."Credit Amount".AsDEcimal
        else
            EntryRemainingAmount := BankAccountLedgerEntries."Debit Amount".AsDEcimal;
        exit(EntryRemainingAmount);
    end;

    procedure InsertRecordsToProtectedTables()
    begin
    end;

    local procedure UpdateAccountsInGeneralPostingSetup()
    var
        NormalGeneralPostingSetup: Record "General Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetupInvtFull(NormalGeneralPostingSetup);
        with GeneralPostingSetup do
            if FindSet then
                repeat
                    if "Direct Cost Applied Account" = '' then
                        Validate("Direct Cost Applied Account", NormalGeneralPostingSetup."Direct Cost Applied Account")
                    else
                        // Due to FR DDT COD119032 "Direct Cost Applied Account" may be equal to "Inventory Adjmt. Account"
                        if "Direct Cost Applied Account" = "Inventory Adjmt. Account" then
                            Validate("Direct Cost Applied Account", LibraryERM.CreateGLAccountNo);
                    if "Overhead Applied Account" = '' then
                        Validate("Overhead Applied Account", NormalGeneralPostingSetup."Overhead Applied Account");
                    if "COGS Account" = '' then
                        Validate("COGS Account", NormalGeneralPostingSetup."COGS Account");
                    if "Purchase Variance Account" = '' then
                        Validate("Purchase Variance Account", NormalGeneralPostingSetup."Purchase Variance Account");
                    if "Inventory Adjmt. Account" = '' then
                        Validate("Inventory Adjmt. Account", NormalGeneralPostingSetup."Inventory Adjmt. Account");
                    if "Purch. Prepayments Account" = '' then
                        Validate("Purch. Prepayments Account", NormalGeneralPostingSetup."Purch. Prepayments Account");
                    if "Sales Prepayments Account" = '' then
                        Validate("Sales Prepayments Account", NormalGeneralPostingSetup."Sales Prepayments Account");
                    Modify(true);
                until Next = 0;
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure DeleteExtraGeneralJournalTemplate()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.FindSet();
        repeat
            GenJournalBatch.SetRange("Journal Template Name", GenJournalTemplate.Name);
            if GenJournalBatch.Count = 0 then
                GenJournalTemplate.Delete(true);
        until GenJournalTemplate.Next = 0;
    end;

    local procedure DisableAdjustForPmtDiscInGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Adjust for Payment Disc.", false);
        GeneralLedgerSetup.Modify(true);
    end;
}

