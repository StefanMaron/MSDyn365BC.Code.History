codeunit 383 "Upd. Pending Prepmt. Sales"
{

    trigger OnRun()
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
    begin
        PrepaymentMgt.UpdatePendingPrepaymentSales;
    end;
}

