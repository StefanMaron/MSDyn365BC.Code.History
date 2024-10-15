report 17403 "Import Payroll Calc. Functions"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Import Payroll Calc. Functions';
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
        PayrollDataExchangeMgt.ImportPayrollCalcFunctions('');
    end;

    var
        PayrollDataExchangeMgt: Codeunit "Payroll Data Exchange Mgt.";
}

