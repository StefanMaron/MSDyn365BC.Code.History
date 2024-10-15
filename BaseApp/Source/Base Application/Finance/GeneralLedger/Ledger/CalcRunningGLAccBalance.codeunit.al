namespace Microsoft.Finance.GeneralLedger.Ledger;

codeunit 122 "Calc. Running GL. Acc. Balance"
{
    InherentPermissions = X;

    var
        GLEntry2: Record "G/L Entry";
        DayTotals: Dictionary of [Date, Decimal];
        DayTotalsACY: Dictionary of [Date, Decimal];
        EntryValues: Dictionary of [Integer, Decimal];
        EntryValuesACY: Dictionary of [Integer, Decimal];
        PrevAccNo: Code[20];

    procedure GetGLAccBalance(var GLEntry: Record "G/L Entry"): Decimal
    var
        RunningBalance: Decimal;
        RunningBalanceACY: Decimal;
    begin
        CalcGLAccBalance(GLEntry, RunningBalance, RunningBalanceACY);
        exit(RunningBalance);
    end;

    procedure GetGLAccBalanceACY(var GLEntry: Record "G/L Entry"): Decimal
    var
        RunningBalance: Decimal;
        RunningBalanceACY: Decimal;
    begin
        CalcGLAccBalance(GLEntry, RunningBalance, RunningBalanceACY);
        exit(RunningBalanceACY);
    end;

    local procedure CalcGLAccBalance(var GLEntry: Record "G/L Entry"; var RunningBalance: Decimal; var RunningBalanceACY: Decimal)
    var
        DateTotal: Decimal;
        DateTotalACY: Decimal;
    begin
        if (PrevAccNo <> '') and (PrevAccNo <> GLEntry."G/L Account No.") then begin
            Clear(DayTotals);
            Clear(DayTotalsACY);
        end;
        PrevAccNo := GLEntry."G/L Account No.";

        if EntryValues.Get(GLEntry."Entry No.", RunningBalance) and EntryValuesACY.Get(GLEntry."Entry No.", RunningBalanceACY) then
            exit;

        GLEntry2.Reset();
        GLEntry2.SetLoadFields("Entry No.", "G/L Account No.", "Posting Date", Amount, "Additional-Currency Amount");
        GLEntry2.SetRange("G/L Account No.", GLEntry."G/L Account No.");
        if not (DayTotals.Get(GLEntry."Posting Date", DateTotal) and DayTotalsACY.Get(GLEntry."Posting Date", DateTotalACY)) then begin
            GLEntry2.SetFilter("Posting Date", '<=%1', GLEntry."Posting Date");
            GLEntry2.CalcSums(Amount, "Additional-Currency Amount");
            DateTotal := GLEntry2.Amount;
            DateTotalACY := GLEntry2."Additional-Currency Amount";
            DayTotals.Add(GLEntry."Posting Date", DateTotal);
            DayTotalsACY.Add(GLEntry."Posting Date", DateTotalACY);
        end;
        GLEntry2.SetRange("Posting Date", GLEntry."Posting Date");
        GLEntry2.SetFilter("Entry No.", '>%1', GLEntry."Entry No.");
        GLEntry2.CalcSums(Amount, "Additional-Currency Amount");
        RunningBalance := DateTotal - GLEntry2.Amount;
        RunningBalanceACY := DateTotalACY - GLEntry2."Additional-Currency Amount";
        EntryValues.Add(GLEntry."Entry No.", RunningBalance);
        EntryValuesACY.Add(GLEntry."Entry No.", RunningBalanceACY);
    end;
}