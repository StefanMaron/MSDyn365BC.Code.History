namespace Microsoft.Inventory.Ledger;

using Microsoft.Inventory.Counting.Journal;

codeunit 390 "Item Reg.-Show Inventory Ledg."
{
    TableNo = "Item Register";

    trigger OnRun()
    begin
        PhysInvtLedgEntry.SetRange("Entry No.", Rec."From Phys. Inventory Entry No.", Rec."To Phys. Inventory Entry No.");
        PAGE.Run(PAGE::"Phys. Inventory Ledger Entries", PhysInvtLedgEntry);
    end;

    var
        PhysInvtLedgEntry: Record "Phys. Inventory Ledger Entry";
}

