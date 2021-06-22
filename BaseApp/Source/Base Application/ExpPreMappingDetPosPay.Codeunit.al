codeunit 1704 "Exp. Pre-Mapping Det Pos. Pay"
{
    Permissions = TableData "Positive Pay Detail" = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        LineNo: Integer;
    begin
        CheckLedgerEntry.SetRange("Data Exch. Entry No.", "Entry No.");
        PreparePosPayDetails(CheckLedgerEntry, "Entry No.", LineNo);

        // Reset filters and set it on the Data Exch. Voided Entry No.
        CheckLedgerEntry.Reset();
        CheckLedgerEntry.SetRange("Data Exch. Voided Entry No.", "Entry No.");
        PreparePosPayDetails(CheckLedgerEntry, "Entry No.", LineNo);
    end;

    var
        ProgressMsg: Label 'Preprocessing line no. #1######.';

    local procedure PreparePosPayDetails(var CheckLedgerEntry: Record "Check Ledger Entry"; DataExchangeEntryNo: Integer; var LineNo: Integer)
    var
        Window: Dialog;
    begin
        if CheckLedgerEntry.FindSet then begin
            Window.Open(ProgressMsg);
            repeat
                LineNo += 1;
                Window.Update(1, LineNo);
                PreparePosPayDetail(CheckLedgerEntry, DataExchangeEntryNo, LineNo);
            until CheckLedgerEntry.Next = 0;
            Window.Close;
        end;
    end;

    local procedure PreparePosPayDetail(CheckLedgerEntry: Record "Check Ledger Entry"; DataExchangeEntryNo: Integer; LineNo: Integer)
    var
        BankAccount: Record "Bank Account";
        PosPayDetail: Record "Positive Pay Detail";
    begin
        BankAccount.Get(CheckLedgerEntry."Bank Account No.");

        with PosPayDetail do begin
            Init;
            "Data Exch. Entry No." := DataExchangeEntryNo;
            "Entry No." := LineNo;
            "Account Number" := BankAccount."Bank Account No.";
            if DataExchangeEntryNo = CheckLedgerEntry."Data Exch. Voided Entry No." then begin
                // V for Void legend
                "Record Type Code" := 'V';
                "Void Check Indicator" := 'V';
            end else begin
                // O for Open legend
                "Record Type Code" := 'O';
                "Void Check Indicator" := '';
            end;
            "Check Number" := CheckLedgerEntry."Check No.";
            Amount := CheckLedgerEntry.Amount;
            Payee := CheckLedgerEntry.GetPayee;
            "Issue Date" := CheckLedgerEntry."Check Date";
            if BankAccount."Currency Code" <> '' then
                "Currency Code" := BankAccount."Currency Code";

            Insert(true);
        end;
    end;
}

