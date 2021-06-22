codeunit 570 "G/L Account Category Mgt."
{

    trigger OnRun()
    begin
        InitializeAccountCategories;
    end;

    var
        BalanceColumnNameTxt: Label 'M-BALANCE', Comment = 'Max 10 char';
        BalanceColumnDescTxt: Label 'Balance', Comment = 'Max 10 char';
        NetChangeColumnNameTxt: Label 'M-NETCHANG', Comment = 'Max 10 char';
        NetChangeColumnDescTxt: Label 'Net Change', Comment = 'Max 10 char';
        BalanceSheetCodeTxt: Label 'M-BALANCE', Comment = 'Max 10 char';
        BalanceSheetDescTxt: Label 'Balance Sheet', Comment = 'Max 80 chars';
        IncomeStmdCodeTxt: Label 'M-INCOME', Comment = 'Max 10 chars';
        IncomeStmdDescTxt: Label 'Income Statement', Comment = 'Max 80 chars';
        CashFlowCodeTxt: Label 'M-CASHFLOW', Comment = 'Max 10 chars';
        CashFlowDescTxt: Label 'Cash Flow Statement', Comment = 'Max 80 chars';
        RetainedEarnCodeTxt: Label 'M-RETAIND', Comment = 'Max 10 char.';
        RetainedEarnDescTxt: Label 'Retained Earnings', Comment = 'Max 80 chars';
        MissingSetupErr: Label 'You must define a %1 in %2 before performing this function.', Comment = '%1 = field name, %2 = table name.';
        CurrentAssetsTxt: Label 'Current Assets';
        ARTxt: Label 'Accounts Receivable';
        CashTxt: Label 'Cash';
        PrepaidExpensesTxt: Label 'Prepaid Expenses';
        InventoryTxt: Label 'Inventory';
        FixedAssetsTxt: Label 'Fixed Assets';
        EquipementTxt: Label 'Equipment';
        AccumDeprecTxt: Label 'Accumulated Depreciation';
        CurrentLiabilitiesTxt: Label 'Current Liabilities';
        PayrollLiabilitiesTxt: Label 'Payroll Liabilities';
        LongTermLiabilitiesTxt: Label 'Long Term Liabilities';
        CommonStockTxt: Label 'Common Stock';
        RetEarningsTxt: Label 'Retained Earnings';
        DistrToShareholdersTxt: Label 'Distributions to Shareholders';
        IncomeServiceTxt: Label 'Income, Services';
        IncomeProdSalesTxt: Label 'Income, Product Sales';
        IncomeSalesDiscountsTxt: Label 'Sales Discounts';
        IncomeSalesReturnsTxt: Label 'Sales Returns & Allowances';
        IncomeInterestTxt: Label 'Income, Interest';
        COGSLaborTxt: Label 'Labor';
        COGSMaterialsTxt: Label 'Materials';
        COGSDiscountsGrantedTxt: Label 'Discounts Granted';
        RentExpenseTxt: Label 'Rent Expense';
        AdvertisingExpenseTxt: Label 'Advertising Expense';
        InterestExpenseTxt: Label 'Interest Expense';
        FeesExpenseTxt: Label 'Fees Expense';
        InsuranceExpenseTxt: Label 'Insurance Expense';
        PayrollExpenseTxt: Label 'Payroll Expense';
        BenefitsExpenseTxt: Label 'Benefits Expense';
        RepairsTxt: Label 'Repairs and Maintenance Expense';
        UtilitiesExpenseTxt: Label 'Utilities Expense';
        OtherIncomeExpenseTxt: Label 'Other Income & Expenses';
        TaxExpenseTxt: Label 'Tax Expense';
        TravelExpenseTxt: Label 'Travel Expense';
        VehicleExpensesTxt: Label 'Vehicle Expenses';
        BadDebtExpenseTxt: Label 'Bad Debt Expense';
        SalariesExpenseTxt: Label 'Salaries Expense';
        JobsCostTxt: Label 'Jobs Cost';
        IncomeJobsTxt: Label 'Income, Jobs';
        JobSalesContraTxt: Label 'Job Sales Contra';
        CreateAccountScheduleForBalanceSheet: Boolean;
        CreateAccountScheduleForIncomeStatement: Boolean;
        CreateAccountScheduleForCashFlowStatement: Boolean;
        CreateAccountScheduleForRetainedEarnings: Boolean;

    procedure InitializeAccountCategories()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccount: Record "G/L Account";
        CategoryID: array[3] of Integer;
    begin
        GLAccount.SetFilter("Account Subcategory Entry No.", '<>0');
        if not GLAccount.IsEmpty then
            if not GLAccountCategory.IsEmpty then
                exit;

        GLAccount.ModifyAll("Account Subcategory Entry No.", 0);
        with GLAccountCategory do begin
            DeleteAll();
            CategoryID[1] := AddCategory(0, 0, "Account Category"::Assets, '', true, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Assets, CurrentAssetsTxt, false, 0);
            CategoryID[3] :=
              AddCategory(0, CategoryID[2], "Account Category"::Assets, CashTxt, false, "Additional Report Definition"::"Cash Accounts");
            CategoryID[3] :=
              AddCategory(
                0, CategoryID[2], "Account Category"::Assets, ARTxt, false,
                "Additional Report Definition"::"Operating Activities");
            CategoryID[3] :=
              AddCategory(
                0, CategoryID[2], "Account Category"::Assets, PrepaidExpensesTxt, false,
                "Additional Report Definition"::"Operating Activities");
            CategoryID[3] :=
              AddCategory(
                0, CategoryID[2], "Account Category"::Assets, InventoryTxt, false,
                "Additional Report Definition"::"Operating Activities");
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Assets, FixedAssetsTxt, false, 0);
            CategoryID[3] :=
              AddCategory(
                0, CategoryID[2], "Account Category"::Assets, EquipementTxt, false,
                "Additional Report Definition"::"Investing Activities");
            CategoryID[3] :=
              AddCategory(
                0, CategoryID[2], "Account Category"::Assets, AccumDeprecTxt, false,
                "Additional Report Definition"::"Investing Activities");
            CategoryID[1] := AddCategory(0, 0, "Account Category"::Liabilities, '', true, 0);
            CategoryID[2] :=
              AddCategory(
                0, CategoryID[1], "Account Category"::Liabilities, CurrentLiabilitiesTxt, false,
                "Additional Report Definition"::"Operating Activities");
            CategoryID[2] :=
              AddCategory(
                0, CategoryID[1], "Account Category"::Liabilities, PayrollLiabilitiesTxt, false,
                "Additional Report Definition"::"Operating Activities");
            CategoryID[2] :=
              AddCategory(
                0, CategoryID[1], "Account Category"::Liabilities, LongTermLiabilitiesTxt, false,
                "Additional Report Definition"::"Financing Activities");
            CategoryID[1] := AddCategory(0, 0, "Account Category"::Equity, '', true, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Equity, CommonStockTxt, false, 0);
            CategoryID[2] :=
              AddCategory(
                0, CategoryID[1], "Account Category"::Equity, RetEarningsTxt, false,
                "Additional Report Definition"::"Retained Earnings");
            CategoryID[2] :=
              AddCategory(
                0, CategoryID[1], "Account Category"::Equity, DistrToShareholdersTxt, false,
                "Additional Report Definition"::"Distribution to Shareholders");
            CategoryID[1] := AddCategory(0, 0, "Account Category"::Income, '', true, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Income, IncomeServiceTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Income, IncomeProdSalesTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Income, IncomeJobsTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Income, IncomeSalesDiscountsTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Income, IncomeSalesReturnsTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Income, IncomeInterestTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Income, JobSalesContraTxt, false, 0);
            CategoryID[1] := AddCategory(0, 0, "Account Category"::"Cost of Goods Sold", '', true, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::"Cost of Goods Sold", COGSLaborTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::"Cost of Goods Sold", COGSMaterialsTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::"Cost of Goods Sold", COGSDiscountsGrantedTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::"Cost of Goods Sold", JobsCostTxt, false, 0);
            CategoryID[1] := AddCategory(0, 0, "Account Category"::Expense, '', true, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, RentExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, AdvertisingExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, InterestExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, FeesExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, InsuranceExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, PayrollExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, BenefitsExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, SalariesExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, RepairsTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, UtilitiesExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, OtherIncomeExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, TaxExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, TravelExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, VehicleExpensesTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, BadDebtExpenseTxt, false, 0);
        end;
    end;

    procedure AddCategory(InsertAfterEntryNo: Integer; ParentEntryNo: Integer; AccountCategory: Option; NewDescription: Text[80]; SystemGenerated: Boolean; CashFlowActivity: Option): Integer
    var
        GLAccountCategory: Record "G/L Account Category";
        InsertAfterSequenceNo: Integer;
        InsertBeforeSequenceNo: Integer;
    begin
        if InsertAfterEntryNo <> 0 then begin
            GLAccountCategory.SetCurrentKey("Presentation Order", "Sibling Sequence No.");
            if GLAccountCategory.Get(InsertAfterEntryNo) then begin
                InsertAfterSequenceNo := GLAccountCategory."Sibling Sequence No.";
                if GLAccountCategory.Next <> 0 then
                    InsertBeforeSequenceNo := GLAccountCategory."Sibling Sequence No.";
            end;
        end;
        GLAccountCategory.Init();
        GLAccountCategory."Entry No." := 0;
        GLAccountCategory."System Generated" := SystemGenerated;
        GLAccountCategory."Parent Entry No." := ParentEntryNo;
        GLAccountCategory.Validate("Account Category", AccountCategory);
        GLAccountCategory.Validate("Additional Report Definition", CashFlowActivity);
        if NewDescription <> '' then
            GLAccountCategory.Description := NewDescription;
        if InsertAfterSequenceNo <> 0 then begin
            if InsertBeforeSequenceNo <> 0 then
                GLAccountCategory."Sibling Sequence No." := (InsertBeforeSequenceNo + InsertAfterSequenceNo) div 2
            else
                GLAccountCategory."Sibling Sequence No." := InsertAfterSequenceNo + 10000;
        end;
        GLAccountCategory.Insert(true);
        GLAccountCategory.UpdatePresentationOrder;
        exit(GLAccountCategory."Entry No.");
    end;

    procedure InitializeStandardAccountSchedules()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if not GeneralLedgerSetup.Get then
            exit;

        AddColumnLayout(BalanceColumnNameTxt, BalanceColumnDescTxt, true);
        AddColumnLayout(NetChangeColumnNameTxt, NetChangeColumnDescTxt, false);

        if GeneralLedgerSetup."Acc. Sched. for Balance Sheet" = '' then begin
            GeneralLedgerSetup."Acc. Sched. for Balance Sheet" := CreateUniqueAccSchedName(BalanceSheetCodeTxt);
            CreateAccountScheduleForBalanceSheet := true;
        end;

        if GeneralLedgerSetup."Acc. Sched. for Income Stmt." = '' then begin
            GeneralLedgerSetup."Acc. Sched. for Income Stmt." := CreateUniqueAccSchedName(IncomeStmdCodeTxt);
            CreateAccountScheduleForIncomeStatement := true;
        end;

        if GeneralLedgerSetup."Acc. Sched. for Cash Flow Stmt" = '' then begin
            GeneralLedgerSetup."Acc. Sched. for Cash Flow Stmt" := CreateUniqueAccSchedName(CashFlowCodeTxt);
            CreateAccountScheduleForCashFlowStatement := true;
        end;

        if GeneralLedgerSetup."Acc. Sched. for Retained Earn." = '' then begin
            GeneralLedgerSetup."Acc. Sched. for Retained Earn." := CreateUniqueAccSchedName(RetainedEarnCodeTxt);
            CreateAccountScheduleForRetainedEarnings := true;
        end;

        GeneralLedgerSetup.Modify();

        AddAccountSchedule(GeneralLedgerSetup."Acc. Sched. for Balance Sheet", BalanceSheetDescTxt, BalanceColumnNameTxt);
        AddAccountSchedule(GeneralLedgerSetup."Acc. Sched. for Income Stmt.", IncomeStmdDescTxt, NetChangeColumnNameTxt);
        AddAccountSchedule(GeneralLedgerSetup."Acc. Sched. for Cash Flow Stmt", CashFlowDescTxt, NetChangeColumnNameTxt);
        AddAccountSchedule(GeneralLedgerSetup."Acc. Sched. for Retained Earn.", RetainedEarnDescTxt, NetChangeColumnNameTxt);
    end;

    local procedure AddAccountSchedule(NewName: Code[10]; NewDescription: Text[80]; DefaultColumnName: Code[10])
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        if AccScheduleName.Get(NewName) then
            exit;
        AccScheduleName.Init();
        AccScheduleName.Name := NewName;
        AccScheduleName.Description := NewDescription;
        AccScheduleName."Default Column Layout" := DefaultColumnName;
        AccScheduleName.Insert();
    end;

    local procedure AddColumnLayout(NewName: Code[10]; NewDescription: Text[80]; IsBalance: Boolean)
    var
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
    begin
        if ColumnLayoutName.Get(NewName) then
            exit;
        ColumnLayoutName.Init();
        ColumnLayoutName.Name := NewName;
        ColumnLayoutName.Description := NewDescription;
        ColumnLayoutName.Insert();

        ColumnLayout.Init();
        ColumnLayout."Column Layout Name" := NewName;
        ColumnLayout."Line No." := 10000;
        ColumnLayout."Column Header" := CopyStr(NewDescription, 1, MaxStrLen(ColumnLayout."Column Header"));
        if IsBalance then
            ColumnLayout."Column Type" := ColumnLayout."Column Type"::"Balance at Date"
        else
            ColumnLayout."Column Type" := ColumnLayout."Column Type"::"Net Change";
        ColumnLayout.Insert();
    end;

    procedure GetGLSetup(var GeneralLedgerSetup: Record "General Ledger Setup")
    var
        CategGenerateAccSchedules: Codeunit "Categ. Generate Acc. Schedules";
    begin
        GeneralLedgerSetup.Get();
        if AnyAccSchedSetupMissing(GeneralLedgerSetup) then begin
            InitializeStandardAccountSchedules;
            GeneralLedgerSetup.Get();
            if AnyAccSchedSetupMissing(GeneralLedgerSetup) then
                Error(MissingSetupErr, GeneralLedgerSetup.FieldCaption("Acc. Sched. for Balance Sheet"), GeneralLedgerSetup.TableCaption);
            Commit();

            if CreateAccountScheduleForBalanceSheet then begin
                CategGenerateAccSchedules.CreateBalanceSheet;
                CreateAccountScheduleForBalanceSheet := false;
            end;

            if CreateAccountScheduleForCashFlowStatement then begin
                CategGenerateAccSchedules.CreateCashFlowStatement;
                CreateAccountScheduleForCashFlowStatement := false;
            end;

            if CreateAccountScheduleForIncomeStatement then begin
                CategGenerateAccSchedules.CreateIncomeStatement;
                CreateAccountScheduleForIncomeStatement := false;
            end;

            if CreateAccountScheduleForRetainedEarnings then begin
                CategGenerateAccSchedules.CreateRetainedEarningsStatement;
                CreateAccountScheduleForRetainedEarnings := false;
            end;
            Commit();
        end;
    end;

    local procedure CreateUniqueAccSchedName(SuggestedName: Code[10]): Code[10]
    var
        AccScheduleName: Record "Acc. Schedule Name";
        i: Integer;
    begin
        while AccScheduleName.Get(SuggestedName) and (i < 1000) do
            SuggestedName := GenerateNextName(SuggestedName, i);
        exit(SuggestedName);
    end;

    local procedure GenerateNextName(SuggestedName: Code[10]; var i: Integer): Code[10]
    var
        NumPart: Code[3];
    begin
        i += 1;
        NumPart := CopyStr(Format(i), 1, MaxStrLen(NumPart));
        exit(CopyStr(SuggestedName, 1, MaxStrLen(SuggestedName) - StrLen(NumPart)) + NumPart);
    end;

    procedure RunAccountScheduleReport(AccSchedName: Code[10])
    var
        AccountSchedule: Report "Account Schedule";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRunAccountScheduleReport(AccSchedName, IsHandled);
        if IsHandled then
            exit;

        AccountSchedule.InitAccSched;
        AccountSchedule.SetAccSchedNameNonEditable(AccSchedName);
        AccountSchedule.Run;
    end;

    local procedure AnyAccSchedSetupMissing(var GeneralLedgerSetup: Record "General Ledger Setup"): Boolean
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        if (GeneralLedgerSetup."Acc. Sched. for Balance Sheet" = '') or
           (GeneralLedgerSetup."Acc. Sched. for Cash Flow Stmt" = '') or
           (GeneralLedgerSetup."Acc. Sched. for Income Stmt." = '') or
           (GeneralLedgerSetup."Acc. Sched. for Retained Earn." = '')
        then
            exit(true);
        if not AccScheduleName.Get(GeneralLedgerSetup."Acc. Sched. for Balance Sheet") then
            exit(true);
        if not AccScheduleName.Get(GeneralLedgerSetup."Acc. Sched. for Cash Flow Stmt") then
            exit(true);
        if not AccScheduleName.Get(GeneralLedgerSetup."Acc. Sched. for Income Stmt.") then
            exit(true);
        if not AccScheduleName.Get(GeneralLedgerSetup."Acc. Sched. for Retained Earn.") then
            exit(true);
        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, 2, 'OnCompanyInitialize', '', false, false)]
    local procedure OnInitializeCompany()
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        if not GLAccountCategory.IsEmpty then
            exit;

        OnBeforeInitializeCompany;

        InitializeAccountCategories;
        CODEUNIT.Run(CODEUNIT::"Categ. Generate Acc. Schedules");

        OnAfterInitializeCompany;
    end;

    procedure GetCurrentAssets(): Text
    begin
        exit(CurrentAssetsTxt);
    end;

    procedure GetAR(): Text
    begin
        exit(ARTxt);
    end;

    procedure GetCash(): Text
    begin
        exit(CashTxt);
    end;

    procedure GetPrepaidExpenses(): Text
    begin
        exit(PrepaidExpensesTxt);
    end;

    procedure GetInventory(): Text
    begin
        exit(InventoryTxt);
    end;

    procedure GetFixedAssets(): Text
    begin
        exit(FixedAssetsTxt);
    end;

    procedure GetEquipment(): Text
    begin
        exit(EquipementTxt);
    end;

    procedure GetAccumDeprec(): Text
    begin
        exit(AccumDeprecTxt);
    end;

    procedure GetCurrentLiabilities(): Text
    begin
        exit(CurrentLiabilitiesTxt);
    end;

    procedure GetPayrollLiabilities(): Text
    begin
        exit(PayrollLiabilitiesTxt);
    end;

    procedure GetLongTermLiabilities(): Text
    begin
        exit(LongTermLiabilitiesTxt);
    end;

    procedure GetCommonStock(): Text
    begin
        exit(CommonStockTxt);
    end;

    procedure GetRetEarnings(): Text
    begin
        exit(RetEarningsTxt);
    end;

    procedure GetDistrToShareholders(): Text
    begin
        exit(DistrToShareholdersTxt);
    end;

    procedure GetIncomeService(): Text
    begin
        exit(IncomeServiceTxt);
    end;

    procedure GetIncomeProdSales(): Text
    begin
        exit(IncomeProdSalesTxt);
    end;

    procedure GetIncomeSalesDiscounts(): Text
    begin
        exit(IncomeSalesDiscountsTxt);
    end;

    procedure GetIncomeSalesReturns(): Text
    begin
        exit(IncomeSalesReturnsTxt);
    end;

    procedure GetIncomeInterest(): Text
    begin
        exit(IncomeInterestTxt);
    end;

    procedure GetCOGSLabor(): Text
    begin
        exit(COGSLaborTxt);
    end;

    procedure GetCOGSMaterials(): Text
    begin
        exit(COGSMaterialsTxt);
    end;

    procedure GetCOGSDiscountsGranted(): Text
    begin
        exit(COGSDiscountsGrantedTxt);
    end;

    procedure GetRentExpense(): Text
    begin
        exit(RentExpenseTxt);
    end;

    procedure GetAdvertisingExpense(): Text
    begin
        exit(AdvertisingExpenseTxt);
    end;

    procedure GetInterestExpense(): Text
    begin
        exit(InterestExpenseTxt);
    end;

    procedure GetFeesExpense(): Text
    begin
        exit(FeesExpenseTxt);
    end;

    procedure GetInsuranceExpense(): Text
    begin
        exit(InsuranceExpenseTxt);
    end;

    procedure GetPayrollExpense(): Text
    begin
        exit(PayrollExpenseTxt);
    end;

    procedure GetBenefitsExpense(): Text
    begin
        exit(BenefitsExpenseTxt);
    end;

    procedure GetRepairsExpense(): Text
    begin
        exit(RepairsTxt);
    end;

    procedure GetUtilitiesExpense(): Text
    begin
        exit(UtilitiesExpenseTxt);
    end;

    procedure GetOtherIncomeExpense(): Text
    begin
        exit(OtherIncomeExpenseTxt);
    end;

    procedure GetTaxExpense(): Text
    begin
        exit(TaxExpenseTxt);
    end;

    procedure GetTravelExpense(): Text
    begin
        exit(TravelExpenseTxt);
    end;

    procedure GetVehicleExpenses(): Text
    begin
        exit(VehicleExpensesTxt);
    end;

    procedure GetBadDebtExpense(): Text
    begin
        exit(BadDebtExpenseTxt);
    end;

    procedure GetSalariesExpense(): Text
    begin
        exit(SalariesExpenseTxt);
    end;

    procedure GetJobsCost(): Text
    begin
        exit(JobsCostTxt);
    end;

    procedure GetIncomeJobs(): Text
    begin
        exit(IncomeJobsTxt);
    end;

    procedure GetJobSalesContra(): Text
    begin
        exit(JobSalesContraTxt);
    end;

    procedure GetAccountCategory(var GLAccountCategory: Record "G/L Account Category"; Category: Option)
    begin
        GLAccountCategory.SetRange("Account Category", Category);
        GLAccountCategory.SetRange("Parent Entry No.", 0);
        if GLAccountCategory.FindFirst then;
    end;

    procedure GetAccountSubcategory(var GLAccountCategory: Record "G/L Account Category"; Category: Option; Description: Text)
    begin
        GLAccountCategory.SetRange("Account Category", Category);
        GLAccountCategory.SetFilter("Parent Entry No.", '<>%1', 0);
        GLAccountCategory.SetRange(Description, Description);
        if GLAccountCategory.FindFirst then;
    end;

    procedure GetSubcategoryEntryNo(Category: Option; SubcategoryDescription: Text): Integer
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        GLAccountCategory.SetRange("Account Category", Category);
        GLAccountCategory.SetRange(Description, SubcategoryDescription);
        if GLAccountCategory.FindFirst then
            exit(GLAccountCategory."Entry No.");
    end;

    procedure CheckGLAccount(AccNo: Code[20]; CheckProdPostingGroup: Boolean; CheckDirectPosting: Boolean; AccountCategory: Option; AccountSubcategory: Text)
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo = '' then
            exit;

        GLAcc.Get(AccNo);
        GLAcc.CheckGLAcc;
        if CheckProdPostingGroup then
            GLAcc.TestField("Gen. Prod. Posting Group");
        if CheckDirectPosting then
            GLAcc.TestField("Direct Posting", true);
        if GLAcc."Account Category" = 0 then begin
            GLAcc.Validate("Account Category", AccountCategory);
            if AccountSubcategory <> '' then
                GLAcc.Validate("Account Subcategory Entry No.", GetSubcategoryEntryNo(AccountCategory, AccountSubcategory));
            GLAcc.Modify();
        end;
    end;

    procedure CheckGLAccountWithoutCategory(AccNo: Code[20]; CheckProdPostingGroup: Boolean; CheckDirectPosting: Boolean)
    var
        OptionValueOutOfRange: Integer;
    begin
        OptionValueOutOfRange := -1;
        CheckGLAccount(AccNo, CheckProdPostingGroup, CheckDirectPosting, OptionValueOutOfRange, '');
    end;

    procedure LookupGLAccount(var AccountNo: Code[20]; AccountCategory: Option; AccountSubcategoryFilter: Text)
    var
        GLAccount: Record "G/L Account";
        GLAccountCategory: Record "G/L Account Category";
        GLAccountList: Page "G/L Account List";
        EntryNoFilter: Text;
    begin
        GLAccount.Reset();
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccountCategory.SetRange("Account Category", AccountCategory);
        GLAccountCategory.SetFilter(Description, AccountSubcategoryFilter);
        if not GLAccountCategory.IsEmpty then begin
            EntryNoFilter := '';
            GLAccountCategory.FindSet;
            repeat
                EntryNoFilter := EntryNoFilter + Format(GLAccountCategory."Entry No.") + '|';
            until GLAccountCategory.Next = 0;
            EntryNoFilter := CopyStr(EntryNoFilter, 1, StrLen(EntryNoFilter) - 1);
            GLAccount.SetRange("Account Category", GLAccountCategory."Account Category");
            GLAccount.SetFilter("Account Subcategory Entry No.", EntryNoFilter);
            if not GLAccount.FindFirst then begin
                GLAccount.SetRange("Account Category", 0);
                GLAccount.SetRange("Account Subcategory Entry No.", 0);
            end;
        end;
        GLAccountList.SetTableView(GLAccount);
        GLAccountList.LookupMode(true);
        if GLAccountList.RunModal = ACTION::LookupOK then begin
            GLAccountList.GetRecord(GLAccount);
            AccountNo := GLAccount."No.";
        end;
    end;

    procedure LookupGLAccountWithoutCategory(var AccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        GLAccountList: Page "G/L Account List";
    begin
        GLAccount.Reset();
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccountList.SetTableView(GLAccount);
        GLAccountList.LookupMode(true);
        if GLAccountList.RunModal = ACTION::LookupOK then begin
            GLAccountList.GetRecord(GLAccount);
            AccountNo := GLAccount."No.";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeCompany()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitializeCompany()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRunAccountScheduleReport(AccSchedName: Code[10]; var IsHandled: Boolean)
    begin
    end;
}

