codeunit 245 "Item Reg.-Show Ledger"
{
    TableNo = "Item Register";

    trigger OnRun()
    begin
        ItemLedgEntry.SetRange("Entry No.", "From Entry No.", "To Entry No.");
        PAGE.Run(PAGE::"Item Ledger Entries", ItemLedgEntry);
    end;

    var
        ItemLedgEntry: Record "Item Ledger Entry";
}

