report 17405 "Import Payroll Elements"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Import Payroll Elements';
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
        PayrollDataExchangeMgt.ImportPayrollElements('');
    end;

    var
        PayrollDataExchangeMgt: Codeunit "Payroll Data Exchange Mgt.";
}

