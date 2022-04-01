codeunit 5634 "FA Jnl.-Show Entries"
{
    TableNo = "FA Journal Line";

    trigger OnRun()
    begin
        if "FA Posting Type" <> "FA Posting Type"::Maintenance then begin
            DepreciationCalc.SetFAFilter(FALedgEntry, "FA No.", "Depreciation Book Code", false);
            if "Depreciation Book Code" = '' then
                FALedgEntry.SetRange("Depreciation Book Code");
            if FALedgEntry.Find('+') then;
            PAGE.Run(PAGE::"FA Ledger Entries", FALedgEntry);
        end else begin
            MaintenanceLedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
            MaintenanceLedgEntry.SetRange("FA No.", "FA No.");
            if "Depreciation Book Code" <> '' then
                MaintenanceLedgEntry.SetRange("Depreciation Book Code", "Depreciation Book Code");
            if MaintenanceLedgEntry.FindLast() then;
            PAGE.Run(PAGE::"Maintenance Ledger Entries", MaintenanceLedgEntry);
        end;
    end;

    var
        FALedgEntry: Record "FA Ledger Entry";
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        DepreciationCalc: Codeunit "Depreciation Calculation";
}

