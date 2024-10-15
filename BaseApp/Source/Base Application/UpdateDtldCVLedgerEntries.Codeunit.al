codeunit 10881 "Update Dtld. CV Ledger Entries"
{

    trigger OnRun()
    var
        PaymentReportingMgt: Codeunit "Payment Reporting Mgt.";
    begin
        PaymentReportingMgt.UpdateUnrealizedAdjmtGLAccDtldCustLedgerEntries;
        PaymentReportingMgt.UpdateUnrealizedAdjmtGLAccDtldVendLedgerEntries;
    end;
}

