codeunit 105 "Calc. Running Acc. Balance"
{
    SingleInstance = true;

    var
        BankAccountLedgerEntry2: Record "Bank account ledger entry";
        DayTotals: Dictionary of [Date, Decimal];
        DayTotalsLCY: Dictionary of [Date, Decimal];
        EntryValues: Dictionary of [Integer, Decimal];
        EntryValuesLCY: Dictionary of [Integer, Decimal];
        PrevAccNo: Code[20];
        PrevTableID: Integer;

    procedure GetBankAccBalance(var BankAccountLedgerEntry: Record "Bank account ledger entry"): Decimal
    var
        RunningBalance: Decimal;
        RunningBalanceLCY: Decimal;
    begin
        CalcBankAccBalance(BankAccountLedgerEntry, RunningBalance, RunningBalanceLCY);
        exit(RunningBalance);
    end;

    procedure GetBankAccBalanceLCY(var BankAccountLedgerEntry: Record "Bank account ledger entry"): Decimal
    var
        RunningBalance: Decimal;
        RunningBalanceLCY: Decimal;
    begin
        CalcBankAccBalance(BankAccountLedgerEntry, RunningBalance, RunningBalanceLCY);
        exit(RunningBalanceLCY);
    end;

    local procedure CalcBankAccBalance(var BankAccountLedgerEntry: Record "Bank account ledger entry"; var RunningBalance: Decimal; var RunningBalanceLCY: Decimal)
    var
        DateTotal: Decimal;
        DateTotalLCY: Decimal;
    begin
        if (PrevTableID <> 0) and (PrevTableID <> Database::"Bank Account Ledger Entry") or
           (PrevAccNo <> '') and (PrevAccNo <> BankAccountLedgerEntry."Bank Account No.")
        then begin
            Clear(DayTotals);
            Clear(DayTotalsLCY);
            Clear(EntryValues);
            Clear(EntryValuesLCY);
        end;
        PrevTableID := Database::"Bank Account Ledger Entry";
        PrevAccNo := BankAccountLedgerEntry."Bank Account No.";

        if EntryValues.Get(BankAccountLedgerEntry."Entry No.", RunningBalance) and EntryValuesLCY.Get(BankAccountLedgerEntry."Entry No.", RunningBalanceLCY) then
            exit;

        BankAccountLedgerEntry2.Reset();
        BankAccountLedgerEntry2.SetLoadFields("Entry No.", "Bank Account No.", "Posting Date", Amount, "Amount (LCY)");
        BankAccountLedgerEntry2.SetRange("Bank Account No.", BankAccountLedgerEntry."Bank Account No.");
        if not (DayTotals.Get(BankAccountLedgerEntry."Posting Date", DateTotal) and DayTotalsLCY.Get(BankAccountLedgerEntry."Posting Date", DateTotalLCY)) then begin
            BankAccountLedgerEntry2.SetFilter("Posting Date", '<=%1', BankAccountLedgerEntry."Posting Date");
            BankAccountLedgerEntry2.CalcSums(Amount, "Amount (LCY)");
            DateTotal := BankAccountLedgerEntry2.Amount;
            DateTotalLCY := BankAccountLedgerEntry2."Amount (LCY)";
            DayTotals.Add(BankAccountLedgerEntry."Posting Date", DateTotal);
            DayTotalsLCY.Add(BankAccountLedgerEntry."Posting Date", DateTotalLCY);
        end;
        BankAccountLedgerEntry2.SetRange("Posting Date", BankAccountLedgerEntry."Posting Date");
        BankAccountLedgerEntry2.SetFilter("Entry No.", '>%1', BankAccountLedgerEntry."Entry No.");
        BankAccountLedgerEntry2.CalcSums(Amount, "Amount (LCY)");
        RunningBalance := DateTotal - BankAccountLedgerEntry2.Amount;
        RunningBalanceLCY := DateTotalLCY - BankAccountLedgerEntry2."Amount (LCY)";
        EntryValues.Add(BankAccountLedgerEntry."Entry No.", RunningBalance);
        EntryValuesLCY.Add(BankAccountLedgerEntry."Entry No.", RunningBalanceLCY);
    end;
}