namespace Microsoft.Bank.Reconciliation;

codeunit 1296 "BankPaymentApplLines-Delete"
{
    Permissions = TableData "Posted Payment Recon. Line" = d;
    TableNo = "Posted Payment Recon. Hdr";

    trigger OnRun()
    begin
        PostedPaymentReconLine.SetRange("Bank Account No.", Rec."Bank Account No.");
        PostedPaymentReconLine.SetRange("Statement No.", Rec."Statement No.");
        PostedPaymentReconLine.DeleteAll();
    end;

    var
        PostedPaymentReconLine: Record "Posted Payment Recon. Line";
}

