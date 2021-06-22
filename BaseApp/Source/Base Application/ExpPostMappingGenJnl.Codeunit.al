codeunit 1275 "Exp. Post-Mapping Gen. Jnl."
{
    Permissions = TableData "Credit Transfer Entry" = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        CreditTransferRegister: Record "Credit Transfer Register";
        CreditTransferEntry: Record "Credit Transfer Entry";
        GenJnlLine: Record "Gen. Journal Line";
        Window: Dialog;
        LineNo: Integer;
    begin
        GenJnlLine.SetRange("Data Exch. Entry No.", "Entry No.");
        GenJnlLine.FindSet;

        CreditTransferRegister.SetRange("From Bank Account No.", GenJnlLine."Bal. Account No.");
        CreditTransferRegister.FindLast;

        Window.Open(ProgressMsg);

        repeat
            LineNo += 1;
            Window.Update(1, LineNo);

            CreditTransferEntry.CreateNew(CreditTransferRegister."No.", LineNo,
              GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine.GetAppliesToDocEntryNo,
              GenJnlLine."Posting Date", GenJnlLine."Currency Code", GenJnlLine.Amount, '',
              GenJnlLine."Recipient Bank Account", GenJnlLine."Message to Recipient");
        until GenJnlLine.Next = 0;

        Window.Close;
    end;

    var
        ProgressMsg: Label 'Post-processing line no. #1######.';
}

