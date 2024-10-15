codeunit 7000090 "Payment order - Export N34"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        PaymentOrder: Record "Payment Order";
    begin
        PaymentOrder.SetRange("No.", GetFilter("Document No."));
        if PaymentOrder.IsEmpty then
            Error(ExportPaymentErr);
        Commit;
        REPORT.Run(REPORT::"Payment order - Export N34", true, false, PaymentOrder);
    end;

    var
        ExportPaymentErr: Label 'You cannot export payments from Payment Journal with the selected Payment Export Format in Bal. Account No.';
}

