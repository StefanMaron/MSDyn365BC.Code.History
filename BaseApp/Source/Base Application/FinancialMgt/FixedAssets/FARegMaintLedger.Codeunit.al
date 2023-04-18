codeunit 5650 "FA Reg.-MaintLedger"
{
    TableNo = "FA Register";

    trigger OnRun()
    begin
        MaintenanceLedgEntry.SetRange("Entry No.", "From Maintenance Entry No.", "To Maintenance Entry No.");
        PAGE.Run(PAGE::"Maintenance Ledger Entries", MaintenanceLedgEntry);
    end;

    var
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
}

