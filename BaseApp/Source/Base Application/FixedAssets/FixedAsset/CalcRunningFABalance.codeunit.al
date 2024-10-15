namespace Microsoft.FixedAssets.Ledger;

codeunit 123 "Calc. Running FA Balance"
{
    InherentPermissions = X;

    var
        FALedgerEntry2: Record "FA Ledger Entry";
        ClientTypeManagement: Codeunit System.Environment."Client Type Management";
        DayTotals: Dictionary of [Date, Decimal];
        EntryValues: Dictionary of [Integer, Decimal];
        PrevAccNo: Code[20];
        PrevDebrBook: Code[10];

    procedure GetFABalance(var FALedgerEntry: Record "FA Ledger Entry"): Decimal
    var
        RunningBalance: Decimal;
    begin
        CalcFABalance(FALedgerEntry, RunningBalance);
        exit(RunningBalance);
    end;

    local procedure CalcFABalance(var FALedgerEntry: Record "FA Ledger Entry"; var RunningBalance: Decimal)
    var
        DateTotal: Decimal;
    begin
        if ClientTypeManagement.GetCurrentClientType() in [ClientType::OData, ClientType::ODataV4] then
            exit;
        if (PrevAccNo <> '') and (PrevAccNo <> FALedgerEntry."FA No.") or (PrevDebrBook <> '') and (PrevDebrBook <> FALedgerEntry."Depreciation Book Code") then
            Clear(DayTotals);
        PrevAccNo := FALedgerEntry."FA No.";
        PrevDebrBook := FALedgerEntry."Depreciation Book Code";

        if EntryValues.Get(FALedgerEntry."Entry No.", RunningBalance) then
            exit;

        FALedgerEntry2.Reset();
        FALedgerEntry2.SetLoadFields("Entry No.", "FA No.", "Posting Date", Amount);
        FALedgerEntry2.SetRange("FA No.", FALedgerEntry."FA No.");
        FALedgerEntry2.SetRange("Depreciation Book Code", FALedgerEntry."Depreciation Book Code");
        if not DayTotals.Get(FALedgerEntry."Posting Date", DateTotal) then begin
            FALedgerEntry2.SetFilter("Posting Date", '<=%1', FALedgerEntry."Posting Date");
            FALedgerEntry2.CalcSums(Amount);
            DateTotal := FALedgerEntry2.Amount;
            DayTotals.Add(FALedgerEntry."Posting Date", DateTotal);
        end;
        FALedgerEntry2.SetRange("Posting Date", FALedgerEntry."Posting Date");
        FALedgerEntry2.SetFilter("Entry No.", '>%1', FALedgerEntry."Entry No.");
        FALedgerEntry2.CalcSums(Amount);
        RunningBalance := DateTotal - FALedgerEntry2.Amount;
        EntryValues.Add(FALedgerEntry."Entry No.", RunningBalance);
    end;
}