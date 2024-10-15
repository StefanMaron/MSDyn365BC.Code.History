namespace Microsoft.Service.Ledger;

codeunit 5919 "Serv Reg.-Show WarrLdgEntries"
{
    TableNo = "Service Register";

    trigger OnRun()
    begin
        WarrLedgEntry.Reset();
        WarrLedgEntry.SetRange("Entry No.", Rec."From Warranty Entry No.", Rec."To Warranty Entry No.");
        PAGE.Run(PAGE::"Warranty Ledger Entries", WarrLedgEntry);
    end;

    var
        WarrLedgEntry: Record "Warranty Ledger Entry";
}

