report 17404 "Import Payroll Calc. Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Import Payroll Calc. Groups';
    ProcessingOnly = true;
    UsageCategory = Tasks;
    UseRequestPage = false;

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;

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

    trigger OnPostReport()
    begin
        PayrollDataExchangeMgt.ImportPayrollCalcGroups('');
    end;

    var
        PayrollDataExchangeMgt: Codeunit "Payroll Data Exchange Mgt.";
}

