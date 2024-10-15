namespace Microsoft.Purchases.Document;

using Microsoft.Finance.ReceivablesPayables;

codeunit 384 "Upd. Pending Prepmt. Purchase"
{

    trigger OnRun()
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
    begin
        PrepaymentMgt.UpdatePendingPrepaymentPurchase();
    end;
}

