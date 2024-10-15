report 14965 "Import Payroll Analysis Rep."
{
    ApplicationArea = Basic, Suite;
    Caption = 'Imported Payroll Analysis';
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
        PayrollDataExchangeMgt.ImportPayrollAnalysisReports('');
    end;

    var
        PayrollDataExchangeMgt: Codeunit "Payroll Data Exchange Mgt.";
}

