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
    var
        VATPeriod: Record "VAT Period";
        StartingDate: Date;
    begin
        // NAVCZ
        StartingDate := CalcDate('<-2Y>', WorkDate);
        if not VATPeriod.Get(StartingDate) then begin
            VATPeriod.Init();
            VATPeriod."Starting Date" := StartingDate;
            VATPeriod.Insert();
        end;
        // NAVCZ
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
#if not CLEAN18    
        LibraryInventory.UpdateInventoryPostingSetupAll; // NAVCZ
#else
        exit;
#endif        
    end;

    procedure UpdateGenJournalTemplate()
    begin
        exit;
    end;

    procedure UpdateGeneralLedgerSetup()
#if not CLEAN18
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
#endif
    begin
#if not CLEAN18
        // NAVCZ
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Closed Period Entry Pos.Date" := LibraryFiscalYear.GetFirstPostingDate(false);
        GeneralLedgerSetup.Modify();
        // NAVCZ
#else
        exit;
#endif
    end;

    local procedure UpdateGenProdPostingSetupOnPrepAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        GeneralPostingSetup.SetFilter("Sales Prepayments Account", '<>%1', '');
        if GeneralPostingSetup.FindSet then
            repeat
                GLAccount.Get(GeneralPostingSetup."Sales Prepayments Account");
                if GLAccount."Gen. Prod. Posting Group" = '' then begin
                    GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
                    GLAccount.Modify(true);
                end;
            until GeneralPostingSetup.Next = 0;
        GeneralPostingSetup.Reset();
        GeneralPostingSetup.SetFilter("Purch. Prepayments Account", '<>%1', '');
        if GeneralPostingSetup.FindSet then
            repeat
                GLAccount.Get(GeneralPostingSetup."Purch. Prepayments Account");
                if GLAccount."Gen. Prod. Posting Group" = '' then begin
                    GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
                    GLAccount.Modify(true);
                end;
            until GeneralPostingSetup.Next = 0;
    end;

    local procedure UpdateVATPostingSetupOnPrepAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        GeneralPostingSetup.SetFilter("Sales Prepayments Account", '<>%1', '');
        if GeneralPostingSetup.FindSet then
            repeat
                GLAccount.Get(GeneralPostingSetup."Sales Prepayments Account");
                if GLAccount."VAT Prod. Posting Group" = '' then begin
                    GenProdPostingGroup.Get(GeneralPostingSetup."Gen. Prod. Posting Group");
                    GLAccount.Validate("VAT Prod. Posting Group", GenProdPostingGroup."Def. VAT Prod. Posting Group");
                    GLAccount.Modify(true);
                end;
            until GeneralPostingSetup.Next = 0;
        GeneralPostingSetup.Reset();
        GeneralPostingSetup.SetFilter("Purch. Prepayments Account", '<>%1', '');
        if GeneralPostingSetup.FindSet then
            repeat
                GLAccount.Get(GeneralPostingSetup."Purch. Prepayments Account");
                if GLAccount."VAT Prod. Posting Group" = '' then begin
                    GenProdPostingGroup.Get(GeneralPostingSetup."Gen. Prod. Posting Group");
                    GLAccount.Validate("VAT Prod. Posting Group", GenProdPostingGroup."Def. VAT Prod. Posting Group");
                    GLAccount.Modify(true);
                end;
            until GeneralPostingSetup.Next = 0;
    end;

    procedure UpdatePrepaymentAccounts()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // NAVCZ
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Prepayment Type" := GeneralLedgerSetup."Prepayment Type"::Prepayments;
        GeneralLedgerSetup.Modify();

        UpdateVATPostingSetupOnPrepAccount;
        UpdateGenProdPostingSetupOnPrepAccount;
        // NAVCZ
    end;

    procedure UpdatePurchasesPayablesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // NAVCZ
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Allow Document Deletion Before" := CalcDate('<CY>', WorkDate);
        PurchasesPayablesSetup."Default Orig. Doc. VAT Date" :=
          PurchasesPayablesSetup."Default Orig. Doc. VAT Date"::"Posting Date";
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
        SalesReceivablesSetup."Allow Document Deletion Before" := CalcDate('<CY>', WorkDate);
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
    var
        FASetup: Record "FA Setup";
#if not CLEAN18
        FAExtendedPostingGroup: Record "FA Extended Posting Group";
#endif
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPeriod: Record "VAT Period";
        AccountingPeriod: Record "Accounting Period";
    begin
        FASetup.Get();
        FASetup.Validate("FA Acquisition As Custom 2", false);
        FASetup.Modify(true);
#if not CLEAN18
        FAExtendedPostingGroup.DeleteAll();
#endif

        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."Use VAT Date" and VATPeriod.IsEmpty() and not AccountingPeriod.IsEmpty() then begin
            GeneralLedgerSetup."Use VAT Date" := false;
            GeneralLedgerSetup.Modify(true);
        end;
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

    local procedure CreateUserSetup()
    var
        UserSetup: Record "User Setup";
    begin
        // NAVCZ
        UserSetup.Init();
        UserSetup."User ID" := UserId;
        UserSetup."Allow Item Unapply" := true;
        UserSetup."Time Sheet Admin." := true;
        UserSetup."Allow Complete Job" := true;
        if not UserSetup.Insert(true) then
            UserSetup.Modify(true);
    end;
}

