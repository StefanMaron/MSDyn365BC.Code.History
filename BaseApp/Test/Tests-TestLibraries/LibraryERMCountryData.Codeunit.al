codeunit 131305 "Library - ERM Country Data"
{
    // Procedures to create demo data present in W1 but missing in countries


    trigger OnRun()
    begin
    end;

    var
        PCS: Label 'PCS';
        BOX: Label 'BOX';
        IVA: Label 'IVA%1';
        VAT: Label 'VAT%1';

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
        LibraryERM.SetupReportSelection(DummyReportSelections.Usage::"P.Invoice", Report::"Purchase - Invoice");
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
    begin
        exit;
    end;

    procedure UpdateGenProdPostingGroup()
    begin
        InitialSetupForGenProdPostingGroup;
    end;

    procedure CreateGeneralPostingSetupData()
    begin
        exit;
    end;

    procedure CreateUnitsOfMeasure()
    var
        UnitofMeasure: Record "Unit of Measure";
    begin
        if not UnitofMeasure.Get(PCS) then
            CreateUnitOfMeasure(PCS);
        if not UnitofMeasure.Get(BOX) then
            CreateUnitOfMeasure(BOX);
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
    var
        PostedBankRecHeader: Record "Posted Bank Rec. Header";
        PostedBankRecLine: Record "Posted Bank Rec. Line";
        PostedDepositHeader: Record "Posted Deposit Header";
        PostedDepositLine: Record "Posted Deposit Line";
    begin
        PostedBankRecHeader.Insert();
        PostedBankRecLine.Insert();
        PostedDepositHeader.Insert();
        PostedDepositLine.Insert();
    end;

    local procedure CreateUnitOfMeasure("Code": Text)
    var
        UnitofMeasure: Record "Unit of Measure";
    begin
        UnitofMeasure.Init();
        UnitofMeasure.Code := Code;
        UnitofMeasure.Description := Code;
        UnitofMeasure.Insert();
    end;

    local procedure GetVATProdPostingGroup(VATPerc: Integer): Code[20]
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        if VATProdPostingGroup.Get(StrSubstNo(VAT, VATPerc)) then
            exit(StrSubstNo(VAT, VATPerc));  // This line works for GDL build.
        if VATProdPostingGroup.Get(StrSubstNo(IVA, VATPerc)) then
            exit(StrSubstNo(IVA, VATPerc));  // This line works for local build.
    end;

    local procedure UpdateVATProdPostingGroup(GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        Resource: Record Resource;
        ItemCharge: Record "Item Charge";
    begin
        GLAccount.SetCurrentKey("Gen. Prod. Posting Group");
        GLAccount.SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.SetFilter("VAT Prod. Posting Group", '<>%1', VATProdPostingGroup);
        if GLAccount.FindSet then
            GLAccount.ModifyAll("VAT Prod. Posting Group", VATProdPostingGroup, false);

        Item.SetCurrentKey("Gen. Prod. Posting Group");
        Item.SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
        Item.SetFilter("VAT Prod. Posting Group", '<>%1', VATProdPostingGroup);
        if Item.FindSet then
            Item.ModifyAll("VAT Prod. Posting Group", VATProdPostingGroup, false);

        ItemCharge.SetCurrentKey("Gen. Prod. Posting Group");
        ItemCharge.SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
        ItemCharge.SetFilter("VAT Prod. Posting Group", '<>%1', VATProdPostingGroup);
        if ItemCharge.FindSet then
            ItemCharge.ModifyAll("VAT Prod. Posting Group", VATProdPostingGroup, false);

        Resource.SetCurrentKey("Gen. Prod. Posting Group");
        Resource.SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
        Resource.SetFilter("VAT Prod. Posting Group", '<>%1', VATProdPostingGroup);
        if Resource.FindSet then
            Resource.ModifyAll("VAT Prod. Posting Group", VATProdPostingGroup, false);
    end;

    local procedure InitialSetupForGenProdPostingGroup()
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        DefVATProdPostingGroup: Code[20];
    begin
        // Assign Def. VAT Prod. Posting Group to a Gen. Prod. Posting Group based on W1.
        GenProdPostingGroup.SetFilter("Def. VAT Prod. Posting Group", '');
        if GenProdPostingGroup.FindSet then
            repeat
                DefVATProdPostingGroup := '';
                if GenProdPostingGroup.Code in ['SERVICIOS', 'SERVICES'] then // Hardcoding to match MX.
                    DefVATProdPostingGroup := GetVATProdPostingGroup(10)
                else
                    if VATProdPostingGroup.Get(GenProdPostingGroup.Code) then
                        DefVATProdPostingGroup := GenProdPostingGroup.Code
                    else
                        DefVATProdPostingGroup := GetVATProdPostingGroup(25);


                if DefVATProdPostingGroup <> '' then begin
                    GenProdPostingGroup."Def. VAT Prod. Posting Group" := DefVATProdPostingGroup; // Skip OnValidate trigger which has UI confirmation dialog.
                    UpdateVATProdPostingGroup(GenProdPostingGroup.Code, DefVATProdPostingGroup);
                    GenProdPostingGroup.Modify(true);
                end;
            until GenProdPostingGroup.Next = 0;
    end;
}

