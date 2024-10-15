codeunit 10721 "Create Electronic Payments"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.CopyFilters(Rec);
        GenJnlLine.LockTable;
        if GenJnlLine.IsEmpty then
            Error(ExportPaymentErr);
        Commit;
        REPORT.RunModal(REPORT::"Export Electronic Payments", true, false, GenJnlLine);
    end;

    var
        ExportPaymentErr: Label 'You cannot export the payment order with the selected Bank Export Format in Bank Account No.';
}

