namespace Microsoft.Manufacturing.Capacity;

using Microsoft.Inventory.Ledger;

codeunit 5835 "Item Reg.-Show Cap. Ledger"
{
    TableNo = "Item Register";

    trigger OnRun()
    begin
        CapLedgEntry.SetRange("Entry No.", Rec."From Capacity Entry No.", Rec."To Capacity Entry No.");
        PAGE.Run(PAGE::"Capacity Ledger Entries", CapLedgEntry);
    end;

    var
        CapLedgEntry: Record "Capacity Ledger Entry";
}

