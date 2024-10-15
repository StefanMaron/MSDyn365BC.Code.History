namespace Microsoft.FixedAssets.Maintenance;

using Microsoft.Finance.GeneralLedger.Ledger;

codeunit 5649 "G/L Reg.-Maint.Ledger"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        MaintenanceLedgEntry.SetCurrentKey("G/L Entry No.");
        MaintenanceLedgEntry.SetRange("G/L Entry No.", Rec."From Entry No.", Rec."To Entry No.");
        PAGE.Run(PAGE::"Maintenance Ledger Entries", MaintenanceLedgEntry);
    end;

    var
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
}

