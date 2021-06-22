codeunit 1209 "Export Payment File (Yes/No)"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        BankAcc: Record "Bank Account";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        if not FindSet then
            Error(NothingToExportErr);
        SetRange("Journal Template Name", "Journal Template Name");
        SetRange("Journal Batch Name", "Journal Batch Name");

        GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        GenJnlBatch.TestField("Bal. Account Type", GenJnlBatch."Bal. Account Type"::"Bank Account");
        GenJnlBatch.TestField("Bal. Account No.");

        CheckDocNoOnLines;
        if IsExportedToPaymentFile then
            if not Confirm(ExportAgainQst) then
                exit;
        BankAcc.Get(GenJnlBatch."Bal. Account No.");
        CODEUNIT.Run(BankAcc.GetPaymentExportCodeunitID, Rec);
    end;

    var
        ExportAgainQst: Label 'One or more of the selected lines have already been exported. Do you want to export again?';
        NothingToExportErr: Label 'There is nothing to export.';
}

