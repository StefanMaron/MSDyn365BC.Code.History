namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;

report 151 "Balance Sheet"
{
    AccessByPermission = TableData "G/L Account" = R;
    ApplicationArea = Basic, Suite;
    Caption = 'Balance Sheet';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;
    UseRequestPage = false;

    dataset
    {
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        GLAccountCategoryMgt.GetGLSetup(GeneralLedgerSetup);
        GLAccountCategoryMgt.RunAccountScheduleReport(GeneralLedgerSetup."Fin. Rep. for Balance Sheet");
    end;
}

