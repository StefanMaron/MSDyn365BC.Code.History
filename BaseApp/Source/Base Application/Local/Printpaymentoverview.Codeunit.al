codeunit 15000003 "Print payment overview"
{

    trigger OnRun()
    var
        RemTools: Codeunit "Remittance Tools";
    begin
        RemTools.PrintPaymentOverview(0);
    end;
}

