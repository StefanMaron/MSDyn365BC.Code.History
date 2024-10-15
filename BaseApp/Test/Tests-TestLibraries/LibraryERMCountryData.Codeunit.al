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
    begin
        CreateReverseChargeVATSetup;
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
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"S.Invoice Draft", REPORT::"Standard Sales - Draft Invoice");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"S.Invoice", REPORT::"Standard Sales - Invoice");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"S.Order", REPORT::"Standard Sales - Order Conf.");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::USI, Report::"Standard Sales - Draft Invoice");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"S.Cr.Memo", REPORT::"Standard Sales - Credit Memo");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"SM.Invoice", REPORT::"Service - Invoice");
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"SM.Credit Memo", REPORT::"Service - Credit Memo");
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
        UpdateAccountsInGeneralPostingSetup;
    end;

    procedure UpdateInventoryPostingSetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup."Automatic Cost Posting" := false;
        InventorySetup."Posted Direct Trans. Nos." := LibraryUtility.GetGlobalNoSeriesCode;
        InventorySetup.Modify();
    end;

    procedure UpdateGenJournalTemplate()
    begin
        exit;
    end;

    procedure UpdateGeneralLedgerSetup()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Enable Russian Accounting", false);
        ClearUnrealTypeInVATPostingSetup;
        GLSetup.Validate("Unrealized VAT", false);
        GLSetup.Validate("Mark Cr. Memos as Corrections", false);
        GLSetup.Validate("Void Payment as Correction", false);
        GLSetup.Modify();
    end;

    procedure UpdatePrepaymentAccounts()
    begin
        UpdateVATPostingSetupOnPrepAccount();
        UpdateGenProdPostingSetupOnPrepAccount();
    end;

    procedure UpdatePurchasesPayablesSetup()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        PurchSetup."Discount Posting" := PurchSetup."Discount Posting"::"All Discounts";
        PurchSetup.Validate("Use Prepayment Account", false);
        PurchSetup.Validate("Allow VAT Difference", false);
        PurchSetup.Validate("Transfer Posting Description", false);
        PurchSetup.Validate("Allow Alter Posting Groups", false);
        PurchSetup.Modify(true);
    end;

    procedure UpdateSalesReceivablesSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup."Discount Posting" := SalesSetup."Discount Posting"::"All Discounts";
        SalesSetup.Validate("Use Prepayment Account", false);
        SalesSetup.Validate("Create Prepayment Invoice");
        SalesSetup.Validate("Calc. Inv. Discount", false);
        SalesSetup.Validate("Return Receipt on Credit Memo", false);
        SalesSetup.Validate("Allow VAT Difference", false);
        SalesSetup.Validate("Transfer Posting Description", false);
        SalesSetup.Validate("Calc. VAT per Line", false);
        SalesSetup.Validate("Allow Alter Posting Groups", false);
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
        UpdateAccountsInVATPostingSetup;
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
        ClearStartingDateInNoSeries;
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

    local procedure UpdateAccountsInGeneralPostingSetup()
    var
        NormalGeneralPostingSetup: Record "General Posting Setup";
        GenPostingSetup: Record "General Posting Setup";
    begin
        PrepareNormalGenPostingSetup(NormalGeneralPostingSetup);
        with GenPostingSetup do
            if FindSet(true) then
                repeat
                    if "Sales Account" = '' then
                        Validate("Sales Account", NormalGeneralPostingSetup."Sales Account");
                    if "Purch. Account" = '' then
                        Validate("Purch. Account", NormalGeneralPostingSetup."Purch. Account");
                    if "Sales Credit Memo Account" = '' then
                        Validate("Sales Credit Memo Account", NormalGeneralPostingSetup."Sales Credit Memo Account");
                    if "Purch. Credit Memo Account" = '' then
                        Validate("Purch. Credit Memo Account", NormalGeneralPostingSetup."Purch. Credit Memo Account");
                    if "Sales Prepayments Account" = '' then
                        Validate("Sales Prepayments Account", NormalGeneralPostingSetup."Sales Prepayments Account");
                    if "Purch. Prepayments Account" = '' then
                        Validate("Purch. Prepayments Account", NormalGeneralPostingSetup."Purch. Prepayments Account");
                    if "Purch. Pmt. Disc. Debit Acc." = '' then
                        "Purch. Pmt. Disc. Debit Acc." := NormalGeneralPostingSetup."Purch. Pmt. Disc. Debit Acc.";
                    if "Purch. Pmt. Disc. Credit Acc." = '' then
                        "Purch. Pmt. Disc. Credit Acc." := NormalGeneralPostingSetup."Purch. Pmt. Disc. Credit Acc.";
                    if "Purch. Pmt. Tol. Debit Acc." = '' then
                        "Purch. Pmt. Tol. Debit Acc." := NormalGeneralPostingSetup."Purch. Pmt. Tol. Debit Acc.";
                    if "Purch. Pmt. Tol. Credit Acc." = '' then
                        "Purch. Pmt. Tol. Credit Acc." := NormalGeneralPostingSetup."Purch. Pmt. Tol. Credit Acc.";
                    if "Direct Cost Applied Account" = '' then
                        Validate("Direct Cost Applied Account", NormalGeneralPostingSetup."Direct Cost Applied Account");
                    if "Overhead Applied Account" = '' then
                        Validate("Overhead Applied Account", NormalGeneralPostingSetup."Overhead Applied Account");
                    if "Purchase Variance Account" = '' then
                        Validate("Purchase Variance Account", NormalGeneralPostingSetup."Purchase Variance Account");
                    if "COGS Account" = '' then
                        Validate("COGS Account", NormalGeneralPostingSetup."COGS Account");
                    if "COGS Account (Interim)" = '' then
                        Validate("COGS Account (Interim)", NormalGeneralPostingSetup."COGS Account (Interim)");
                    if "Invt. Accrual Acc. (Interim)" = '' then
                        Validate("Invt. Accrual Acc. (Interim)", NormalGeneralPostingSetup."Invt. Accrual Acc. (Interim)");
                    if "Inventory Adjmt. Account" = '' then
                        Validate("Inventory Adjmt. Account", NormalGeneralPostingSetup."Inventory Adjmt. Account");
                    if "Sales Line Disc. Account" = '' then
                        Validate("Sales Line Disc. Account", NormalGeneralPostingSetup."Sales Line Disc. Account");
                    "Sales Inv. Disc. Account" := "Purch. Account";
                    if "Purch. Line Disc. Account" = '' then
                        "Purch. Line Disc. Account" := "Sales Line Disc. Account";
                    if "Purch. Inv. Disc. Account" = '' then
                        "Purch. Inv. Disc. Account" := "Sales Inv. Disc. Account";
                    Modify(true);
                until Next = 0;
    end;

    local procedure PrepareNormalGenPostingSetup(var GenPostingSetup: Record "General Posting Setup")
    begin
        with GenPostingSetup do begin
            Reset;
            SetFilter("Gen. Bus. Posting Group", '<>%1', '');
            SetFilter("Gen. Prod. Posting Group", '<>%1', '');
            SetFilter("Sales Account", '<>%1', '');
            SetFilter("Purch. Account", '<>%1', '');
            SetFilter("Sales Inv. Disc. Account", '<>%1', '');
            SetFilter("Sales Line Disc. Account", '<>%1', '');
            SetFilter("COGS Account", '<>%1', '');
            SetFilter("Inventory Adjmt. Account", '<>%1', '');
            FindFirst();
            "Sales Inv. Disc. Account" := "Purch. Account";
            if "Purch. Line Disc. Account" = '' then
                "Purch. Line Disc. Account" := "Sales Line Disc. Account";
            if "Purch. Inv. Disc. Account" = '' then
                "Purch. Inv. Disc. Account" := "Sales Inv. Disc. Account";
            if "Invt. Accrual Acc. (Interim)" = '' then
                "Invt. Accrual Acc. (Interim)" := "Inventory Adjmt. Account";
            if "Sales Pmt. Disc. Debit Acc." = '' then
                "Sales Pmt. Disc. Debit Acc." := "Sales Inv. Disc. Account";
            if "Sales Pmt. Disc. Credit Acc." = '' then
                "Sales Pmt. Disc. Credit Acc." := "Sales Line Disc. Account";
            if "COGS Account (Interim)" = '' then
                "COGS Account (Interim)" := "COGS Account";
            if "Direct Cost Applied Account" = '' then
                Validate("Direct Cost Applied Account", "COGS Account");
            if "Overhead Applied Account" = '' then
                Validate("Overhead Applied Account", "COGS Account (Interim)");
            if "Purchase Variance Account" = '' then
                Validate("Purchase Variance Account", "Invt. Accrual Acc. (Interim)");
            if "Sales Prepayments Account" = '' then
                Validate("Sales Prepayments Account", "Purch. Account");
            if "Purch. Prepayments Account" = '' then
                Validate("Purch. Prepayments Account", "Sales Account");
            Modify(true);
        end;
    end;

    local procedure ClearUnrealTypeInVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATPostingSetup.FindSet(true) then
            repeat
                VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
                VATPostingSetup.Modify(true);
            until VATPostingSetup.Next = 0;
    end;

    local procedure UpdateAccountsInVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        NormalVATPostingSetup: Record "VAT Posting Setup";
    begin
        PrepareNormalVATPostingSetup(NormalVATPostingSetup);
        with VATPostingSetup do begin
            if FindSet(true) then
                repeat
                    Validate("Sales VAT Account", NormalVATPostingSetup."Sales VAT Account");
                    Validate("Purchase VAT Account", NormalVATPostingSetup."Purchase VAT Account");
                    Modify(true);
                until Next = 0;
        end;
    end;

    local procedure PrepareNormalVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        with VATPostingSetup do begin
            SetFilter("Sales VAT Account", '<>%1', '');
            LibraryERM.FindVATPostingSetup(VATPostingSetup, "VAT Calculation Type"::"Normal VAT");
            Validate("Purchase VAT Account", "Sales VAT Account");
            Modify(true);
        end;
    end;

    local procedure ClearStartingDateInNoSeries()
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.ModifyAll("Starting Date", 0D);
    end;

    [Scope('OnPrem')]
    procedure CreateReverseChargeVATSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        if VATPostingSetup.IsEmpty() then begin
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            VATProductPostingGroup.Code := VATPostingSetup."VAT Prod. Posting Group" + 'R';
            VATProductPostingGroup.Insert();
            VATPostingSetup."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
            VATPostingSetup."VAT Identifier" := VATPostingSetup."VAT Identifier" + 'R';
            VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
            LibraryERM.CreateGLAccount(GLAccount);
            VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", GLAccount."No.");
            VATPostingSetup.Insert(true);
        end;
    end;
}

