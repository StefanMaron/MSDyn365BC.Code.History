codeunit 390 "Item Reg.-Show Inventory Ledg."
{
    TableNo = "Item Register";

    trigger OnRun()
    begin
        PhysInvtLedgEntry.SetRange("Entry No.", "From Phys. Inventory Entry No.", "To Phys. Inventory Entry No.");
        PAGE.Run(PAGE::"Phys. Inventory Ledger Entries", PhysInvtLedgEntry);
    end;

    var
        PhysInvtLedgEntry: Record "Phys. Inventory Ledger Entry";
}

