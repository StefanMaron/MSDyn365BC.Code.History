report 153 "Customer Statement"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Statement';
    ProcessingOnly = true;
    UsageCategory = Documents;
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
        CustomerLayoutStatement: Codeunit "Customer Layout - Statement";
    begin
        CustomerLayoutStatement.RunReport;
    end;
}

