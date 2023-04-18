report 152 "Calculate Low Level Code"
{
    ApplicationArea = Planning;
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
    var
        ManfacturingSetup: Record "Manufacturing Setup";
    begin
        ManfacturingSetup.Get();
        if ManfacturingSetup."Optimize low-level code calc." then
            Codeunit.Run(Codeunit::"Low-Level Code Calculator")
        else
            CODEUNIT.Run(CODEUNIT::"Calc. Low-level code");
    end;
}

