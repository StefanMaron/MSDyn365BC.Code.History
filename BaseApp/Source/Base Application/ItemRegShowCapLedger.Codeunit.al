codeunit 5835 "Item Reg.-Show Cap. Ledger"
{
    TableNo = "Item Register";

    trigger OnRun()
    begin
        CapLedgEntry.SetRange("Entry No.", "From Capacity Entry No.", "To Capacity Entry No.");
        PAGE.Run(PAGE::"Capacity Ledger Entries", CapLedgEntry);
    end;

    var
        CapLedgEntry: Record "Capacity Ledger Entry";
}

