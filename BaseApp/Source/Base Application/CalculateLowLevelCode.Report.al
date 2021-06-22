report 152 "Calculate Low Level Code"
{
    ApplicationArea = Manufacturing;
    Caption = 'Calculate Low Level Code';
    ProcessingOnly = true;
    UsageCategory = Tasks;
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
    begin
        CODEUNIT.Run(CODEUNIT::"Calc. Low-level code");
    end;
}

