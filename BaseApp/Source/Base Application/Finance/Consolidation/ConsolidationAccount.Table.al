namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Account;
using System.Environment;

table 1829 "Consolidation Account"
{
    Caption = 'Consolidation Account';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(3; "Income/Balance"; Option)
        {
            Caption = 'Income/Balance';
            OptionCaption = 'Income Statement,Balance Sheet';
            OptionMembers = "Income Statement","Balance Sheet";
        }
        field(4; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(5; "Direct Posting"; Boolean)
        {
            Caption = 'Direct Posting';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        XPurchaseVATPERCENTEUTok: Label 'Purchase VAT %1 EU', Comment = '%1=Goods or Services text.';
        XPurchaseVATPERCENTTok: Label 'Purchase VAT %1', Comment = '%1=Goods or Services text.';
        XPurchaseFullVATTok: Label 'Purchase Full VAT %1', Comment = '%1=Goods or Services text.';
        XEmployeesPayableTok: Label 'Employees Payable';
        XSalesVATPERCENTTok: Label 'Sales VAT %1', Comment = '%1=Goods or Services text.';
        XSalesFullVATTok: Label 'Sales Full VAT %1', Comment = '%1=Goods or Services text.';

    [Scope('OnPrem')]
    procedure PopulateAccountsForGB()
    var
        ServicesVATText: Text[30];
        GoodsVATText: Text[30];
    begin
        GoodsVATText := 'Goods';
        ServicesVATText := 'Services';

        InsertData('10100', 'Income, Services', 0, true);
        InsertData('10200', 'Income, Product Sales', 0, false);
        InsertData('10300', 'Sales Discounts', 0, false);
        InsertData('10400', 'Sales Returns & Allowances', 0, false);
        InsertData('10500', 'Interest Income', 0, true);
        InsertData('20100', 'Cost of Materials', 0, false);
        InsertData('20200', 'Cost of Labour', 0, false);
        InsertData('30100', 'Rent Expense', 0, true);
        InsertData('30200', 'Advertising Expense', 0, true);
        InsertData('30300', 'Interest Expense', 0, true);
        InsertData('30400', 'Bank Charges and Fees', 0, true);
        InsertData('30500', 'Processing Fees', 0, true);
        InsertData('30600', 'Bad Debt Expense', 0, true);
        InsertData('30700', 'Salaries Expense', 0, true);
        InsertData('30800', 'Payroll Tax Expense', 0, true);
        InsertData('30900', 'Workers Compensation ', 0, true);
        InsertData('31000', 'Health & Dental Insurance Expense', 0, true);
        InsertData('31100', 'Life Insurance Expense', 0, true);
        InsertData('31200', 'Repairs and Maintenance Expense', 0, true);
        InsertData('31300', 'Utilities Expense', 0, true);
        InsertData('31400', 'Office Supplies Expense', 0, true);
        InsertData('31500', 'Miscellaneous Expense', 0, true);
        InsertData('31600', 'Depreciation, Equipment', 0, false);
        InsertData('31900', 'Rounding', 0, true);

        InsertData('40100', 'Checking account', 1, true);
        InsertData('40200', 'Savings account', 1, true);
        InsertData('40300', 'Petty Cash', 1, true);
        InsertData('40400', 'Accounts Receivable', 1, true);
        InsertData('40500', 'Prepaid Rent', 1, true);
        InsertData('40600', 'Prepaid Insurance', 1, true);
        InsertData('40700', 'Inventory', 1, true);
        InsertData('40800', 'Equipment', 1, true);
        InsertData('40900', 'Accumulated Depreciation', 1, true);
        InsertData('41000', 'Vendor Prepayments', 1, true);
        InsertData('46200', StrSubstNo(XPurchaseVATPERCENTEUTok, GoodsVATText), 1, false);
        InsertData('46210', StrSubstNo(XPurchaseVATPERCENTEUTok, ServicesVATText), 1, false);
        InsertData('46300', StrSubstNo(XPurchaseVATPERCENTTok, GoodsVATText), 1, false);
        InsertData('46310', StrSubstNo(XPurchaseVATPERCENTTok, ServicesVATText), 1, false);
        InsertData('46320', StrSubstNo(XPurchaseFullVATTok, ServicesVATText), 1, true);
        InsertData('46330', StrSubstNo(XPurchaseFullVATTok, GoodsVATText), 1, true);
        InsertData('50100', 'Accounts Payable', 1, true);
        InsertData('50200', 'Purchase Discounts', 1, false);
        InsertData('50300', 'Purchase Returns & Allowances', 1, false);
        InsertData('50400', 'Deferred Revenue', 1, false);
        InsertData('50500', 'Credit Cards', 1, false);
        InsertData('50700', 'Accrued Salaries & Wages', 1, true);
        InsertData('51400', 'Employee Benefits Payable', 1, true);
        InsertData('51500', 'Holiday Compensation Payable', 1, true);
        InsertData('51600', XEmployeesPayableTok, 1, true);
        InsertData('51900', 'Notes Payable', 1, true);
        InsertData('52000', 'Customer Prepayments', 1, true);
        InsertData('56100', StrSubstNo(XSalesVATPERCENTTok, GoodsVATText), 1, false);
        InsertData('56110', StrSubstNo(XSalesVATPERCENTTok, ServicesVATText), 1, false);
        InsertData('56120', StrSubstNo(XSalesFullVATTok, ServicesVATText), 1, true);
        InsertData('56130', StrSubstNo(XSalesFullVATTok, GoodsVATText), 1, true);
        InsertData('60100', 'Share Capital', 1, true);
        InsertData('60200', 'Retained Earnings', 1, true);
        InsertData('60300', 'Dividends', 1, true);
    end;

    procedure PopulateAccounts()
    begin
        InsertData('10100', 'Checking account', 1, true);
    end;

    local procedure InsertData(AccountNo: Code[20]; AccountName: Text[100]; IncomeBalance: Option; DirectPosting: Boolean)
    var
        ConsolidationAccount: Record "Consolidation Account";
    begin
        ConsolidationAccount.Init();
        ConsolidationAccount.Validate("No.", AccountNo);
        ConsolidationAccount.Validate(Name, AccountName);
        ConsolidationAccount.Validate("Direct Posting", DirectPosting);
        ConsolidationAccount.Validate("Income/Balance", IncomeBalance);
        ConsolidationAccount.Insert();
    end;

    procedure PopulateConsolidationAccountsForExistingCompany(ConsolidatedCompany: Text[50])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.ChangeCompany(ConsolidatedCompany);
        GLAccount.Reset();
        GLAccount.SetFilter("Account Type", Format(GLAccount."Account Type"::Posting));
        if GLAccount.Find('-') then
            repeat
                InsertData(GLAccount."No.", GLAccount.Name, GLAccount."Income/Balance", GLAccount."Direct Posting");
            until GLAccount.Next() = 0;
    end;

    procedure ValidateCountry(CountryCode: Code[2]): Boolean
    var
        ApplicationSystemConstants: Codeunit "Application System Constants";
    begin
        if StrPos(ApplicationSystemConstants.ApplicationVersion(), CountryCode) = 1 then
            exit(true);

        exit(false);
    end;
}

