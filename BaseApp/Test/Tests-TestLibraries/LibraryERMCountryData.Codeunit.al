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
        CreateMissingVATPostingSetup;
        CreateReverseChargeVATSetup;
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
        UpdateAccountsInGeneralPostingSetup;
    end;

    procedure UpdateInventoryPostingSetup()
    begin
        SetPostingAccForMfgOverheadVarAcc;
    end;

    procedure UpdateGenJournalTemplate()
    begin
        exit;
    end;

    procedure UpdateGeneralLedgerSetup()
    var
        GLSetup: Record "General Ledger Setup";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
    begin
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup;
        GLSetup.Get();
        GLSetup.Validate("Adjust for Payment Disc.", false);
        GLSetup.Validate("Prepayment Unrealized VAT", false);
        GLSetup.Validate("Inv. Rounding Precision (LCY)", 0.01);
        GLSetup.Modify(true);
    end;

    procedure UpdatePrepaymentAccounts()
    begin
        exit;
    end;

    procedure UpdatePurchasesPayablesSetup()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        PurchSetup."Discount Posting" := PurchSetup."Discount Posting"::"All Discounts";
        PurchSetup.Validate("Receipt on Invoice", true);
        PurchSetup.Modify(true);
    end;

    procedure UpdateSalesReceivablesSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Stockout Warning", true);
        SalesSetup."Discount Posting" := SalesSetup."Discount Posting"::"All Discounts";
        SalesSetup.Validate("Archive Orders", true);
        SalesSetup.Validate("Archive Return Orders", true);
        SalesSetup.Modify(true);
    end;

    procedure UpdateGenProdPostingGroup()
    begin
        exit;
    end;

    procedure CreateGeneralPostingSetupData()
    begin
        CreateMissingGeneralPostingSetup;
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
                        "Purch. Pmt. Disc. Debit Acc." := LibraryERM.CreateGLAccountNo;
                    if "Purch. Pmt. Disc. Credit Acc." = '' then
                        "Purch. Pmt. Disc. Credit Acc." := LibraryERM.CreateGLAccountNo;
                    if "Purch. Pmt. Tol. Debit Acc." = '' then
                        "Purch. Pmt. Tol. Debit Acc." := LibraryERM.CreateGLAccountNo;
                    if "Purch. Pmt. Tol. Credit Acc." = '' then
                        "Purch. Pmt. Tol. Credit Acc." := LibraryERM.CreateGLAccountNo;
                    if "Sales Pmt. Disc. Debit Acc." = '' then
                        "Sales Pmt. Disc. Debit Acc." := LibraryERM.CreateGLAccountNo;
                    if "Sales Pmt. Disc. Credit Acc." = '' then
                        "Sales Pmt. Disc. Credit Acc." := LibraryERM.CreateGLAccountNo;
                    if "Sales Pmt. Tol. Debit Acc." = '' then
                        "Sales Pmt. Tol. Debit Acc." := LibraryERM.CreateGLAccountNo;
                    if "Sales Pmt. Tol. Credit Acc." = '' then
                        "Sales Pmt. Tol. Credit Acc." := LibraryERM.CreateGLAccountNo;
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
                    Validate("Sales Line Disc. Account",
                      GetNotEmptyDiffAccount("Sales Line Disc. Account", NormalGeneralPostingSetup."Sales Line Disc. Account", "Sales Account", "Purch. Line Disc. Account"));
                    Validate("Purch. Line Disc. Account",
                      GetNotEmptyDiffAccount("Purch. Line Disc. Account", NormalGeneralPostingSetup."Purch. Line Disc. Account", "Purch. Account", "Sales Line Disc. Account"));
                    Validate("Sales Inv. Disc. Account",
                      GetNotEmptyDiffAccount("Sales Inv. Disc. Account", NormalGeneralPostingSetup."Sales Inv. Disc. Account", "Sales Account", "Purch. Inv. Disc. Account"));
                    Validate("Purch. Inv. Disc. Account",
                      GetNotEmptyDiffAccount("Purch. Inv. Disc. Account", NormalGeneralPostingSetup."Purch. Inv. Disc. Account", "Purch. Account", "Sales Inv. Disc. Account"));
                    Modify(true);
                until Next = 0;
    end;

    local procedure PrepareNormalGenPostingSetup(var GenPostingSetup: Record "General Posting Setup")
    begin
        with GenPostingSetup do begin
            Reset;
            SetFilter("Gen. Bus. Posting Group", '<>%1', '');
            SetFilter("Gen. Prod. Posting Group", '<>%1', '');
            SetFilter("COGS Account", '<>%1', '');
            SetFilter("Inventory Adjmt. Account", '<>%1', '');
            FindFirst;
            if "COGS Account (Interim)" = '' then
                Validate("COGS Account (Interim)", "COGS Account");
            if "Invt. Accrual Acc. (Interim)" = '' then
                Validate("Invt. Accrual Acc. (Interim)", GenPostingSetup."Inventory Adjmt. Account");
            Modify(true);
        end;
    end;

    local procedure CreateMissingVATPostingSetup()
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATBusPostingGroup.FindSet;
        repeat
            VATProdPostingGroup.FindSet;
            repeat
                CreateVATPostingSetup(VATBusPostingGroup.Code, VATProdPostingGroup.Code);
            until VATProdPostingGroup.Next = 0;
        until VATBusPostingGroup.Next = 0
    end;

    local procedure CreateVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        NormalVATPostingSetup: Record "VAT Posting Setup";
    begin
        with VATPostingSetup do begin
            NormalVATPostingSetup.SetFilter("Sales VAT Account", '<>%1', '');
            NormalVATPostingSetup.SetFilter("Purchase VAT Account", '<>%1', '');
            LibraryERM.FindVATPostingSetup(NormalVATPostingSetup, NormalVATPostingSetup."VAT Calculation Type"::"Normal VAT");
            if Get(VATBusPostingGroup, VATProdPostingGroup) then
                exit;
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProdPostingGroup);
            Validate("VAT Calculation Type", "VAT Calculation Type"::"Normal VAT");
            Validate("VAT %", 25); // Hardcoding to match W1.
            Validate("VAT Identifier", VATProdPostingGroup);
            Validate("Sales VAT Account", NormalVATPostingSetup."Sales VAT Account");
            Validate("Purchase VAT Account", NormalVATPostingSetup."Purchase VAT Account");
            Modify(true);
        end;
    end;

    local procedure UpdateAccountsInVATPostingSetup()
    var
        NormalVATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindNormalVATPostingSetup(NormalVATPostingSetup);
        with VATPostingSetup do begin
            FindSet;
            repeat
                Validate("Sales VAT Account", NormalVATPostingSetup."Sales VAT Account");
                Validate("Purchase VAT Account", NormalVATPostingSetup."Purchase VAT Account");
                Modify(true);
            until Next = 0;
        end;
    end;

    local procedure FindNormalVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        with VATPostingSetup do begin
            SetFilter("Sales VAT Account", '<>%1', '');
            SetFilter("Purchase VAT Account", '<>%1', '');
            LibraryERM.FindVATPostingSetup(VATPostingSetup, "VAT Calculation Type"::"Normal VAT");
        end;
    end;

    local procedure CreateMissingGeneralPostingSetup()
    var
        GenBusPostGroup: Record "Gen. Business Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        NormalGeneralPostingSetup: Record "General Posting Setup";
    begin
        PrepareNormalGenPostingSetup(NormalGeneralPostingSetup);
        GenProdPostingGroup.FindSet;
        repeat
            GenBusPostGroup.FindSet;
            repeat
                CreateGeneralPostingSetup(GenBusPostGroup.Code, GenProdPostingGroup.Code, NormalGeneralPostingSetup);
            until GenBusPostGroup.Next = 0;
            CreateGeneralPostingSetup('', GenProdPostingGroup.Code, NormalGeneralPostingSetup);
        until GenProdPostingGroup.Next = 0;
    end;

    local procedure CreateGeneralPostingSetup(GenBusPostGroupCode: Code[20]; GenProdPostGroupCode: Code[20]; NormalGeneralPostingSetup: Record "General Posting Setup")
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        if not GenPostingSetup.Get(GenBusPostGroupCode, GenProdPostGroupCode) then begin
            LibraryERM.CreateGeneralPostingSetup(GenPostingSetup, GenBusPostGroupCode, GenProdPostGroupCode);
            GenPostingSetup.Validate("Sales Account", NormalGeneralPostingSetup."Sales Account");
            GenPostingSetup.Validate("Purch. Account", NormalGeneralPostingSetup."Purch. Account");
            GenPostingSetup.Validate("Sales Credit Memo Account", NormalGeneralPostingSetup."Sales Credit Memo Account");
            GenPostingSetup.Validate("Purch. Credit Memo Account", NormalGeneralPostingSetup."Purch. Credit Memo Account");
            GenPostingSetup."Purch. Pmt. Disc. Debit Acc." := NormalGeneralPostingSetup."Purch. Pmt. Disc. Debit Acc.";
            GenPostingSetup."Purch. Pmt. Disc. Credit Acc." := NormalGeneralPostingSetup."Purch. Pmt. Disc. Credit Acc.";
            GenPostingSetup."Purch. Pmt. Tol. Debit Acc." := NormalGeneralPostingSetup."Purch. Pmt. Tol. Debit Acc.";
            GenPostingSetup."Purch. Pmt. Tol. Credit Acc." := NormalGeneralPostingSetup."Purch. Pmt. Tol. Credit Acc.";
            GenPostingSetup."Sales Pmt. Disc. Debit Acc." := NormalGeneralPostingSetup."Sales Pmt. Disc. Debit Acc.";
            GenPostingSetup."Sales Pmt. Disc. Credit Acc." := NormalGeneralPostingSetup."Sales Pmt. Disc. Credit Acc.";
            GenPostingSetup."Sales Pmt. Tol. Debit Acc." := NormalGeneralPostingSetup."Sales Pmt. Tol. Debit Acc.";
            GenPostingSetup."Sales Pmt. Tol. Credit Acc." := NormalGeneralPostingSetup."Sales Pmt. Tol. Credit Acc.";
            GenPostingSetup.Validate("Direct Cost Applied Account", NormalGeneralPostingSetup."Direct Cost Applied Account");
            GenPostingSetup.Validate("Overhead Applied Account", NormalGeneralPostingSetup."Overhead Applied Account");
            GenPostingSetup.Validate("Purchase Variance Account", NormalGeneralPostingSetup."Purchase Variance Account");
            GenPostingSetup.Validate("COGS Account", NormalGeneralPostingSetup."COGS Account");
            GenPostingSetup.Validate("Inventory Adjmt. Account", NormalGeneralPostingSetup."Inventory Adjmt. Account");
            GenPostingSetup.Validate("COGS Account (Interim)", NormalGeneralPostingSetup."COGS Account (Interim)");
            GenPostingSetup.Validate("Invt. Accrual Acc. (Interim)", NormalGeneralPostingSetup."Invt. Accrual Acc. (Interim)");
            GenPostingSetup.Validate("Sales Line Disc. Account",
              GetDiffAccount(NormalGeneralPostingSetup."Sales Line Disc. Account", NormalGeneralPostingSetup."Sales Account", NormalGeneralPostingSetup."Purch. Line Disc. Account"));
            GenPostingSetup.Validate("Sales Inv. Disc. Account",
              GetDiffAccount(NormalGeneralPostingSetup."Sales Inv. Disc. Account", NormalGeneralPostingSetup."Sales Account", NormalGeneralPostingSetup."Purch. Inv. Disc. Account"));
            GenPostingSetup.Validate("Purch. Line Disc. Account",
              GetDiffAccount(NormalGeneralPostingSetup."Purch. Line Disc. Account", NormalGeneralPostingSetup."Purch. Account", NormalGeneralPostingSetup."Sales Line Disc. Account"));
            GenPostingSetup.Validate("Purch. Inv. Disc. Account",
              GetDiffAccount(NormalGeneralPostingSetup."Purch. Inv. Disc. Account", NormalGeneralPostingSetup."Purch. Account", NormalGeneralPostingSetup."Sales Inv. Disc. Account"));
            GenPostingSetup.Modify(true);
        end;
    end;

    local procedure GetNotEmptyDiffAccount(BaseGLAccNo: Code[20]; NormalGLAccNo: Code[20]; RelatedGLAccNo: Code[20]; SubstGLAccNo: Code[20]) GLAccNo: Code[20]
    begin
        if BaseGLAccNo = '' then
            GLAccNo := NormalGLAccNo
        else
            GLAccNo := BaseGLAccNo;
        exit(GetDiffAccount(GLAccNo, RelatedGLAccNo, SubstGLAccNo));
    end;

    local procedure GetDiffAccount(GLAccNo: Code[20]; RelatedGLAccNo: Code[20]; SubstGLAccNo: Code[20]): Code[20]
    begin
        if GLAccNo = RelatedGLAccNo then
            exit(SubstGLAccNo);
        exit(GLAccNo);
    end;

    local procedure SetPostingAccForMfgOverheadVarAcc()
    var
        GLAccount: Record "G/L Account";
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        with InventoryPostingSetup do begin
            SetFilter("Mfg. Overhead Variance Account", '<>%1', '');
            if FindSet(true) then
                repeat
                    GLAccount.Get("Mfg. Overhead Variance Account");
                    if GLAccount."Account Type" <> GLAccount."Account Type"::Posting then begin
                        GLAccount.Get("Cap. Overhead Variance Account");
                        GLAccount.TestField("Account Type", GLAccount."Account Type"::Posting);
                        Validate("Mfg. Overhead Variance Account", GLAccount."No.");
                        Modify(true);
                    end;
                until Next = 0;
        end;
    end;

    local procedure CreateReverseChargeVATSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        if VATPostingSetup.IsEmpty then begin
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
            LibraryERM.FindGLAccount(GLAccount);
            VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", GLAccount."No.");
            VATPostingSetup.Modify(true);
        end;
    end;
}

