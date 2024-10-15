namespace Microsoft.FixedAssets.Insurance;

codeunit 5658 "Ins. Reg.-Show Coverage Ledger"
{
    TableNo = "Insurance Register";

    trigger OnRun()
    begin
        InsCoverageLedgEntry.SetRange("Entry No.", Rec."From Entry No.", Rec."To Entry No.");
        PAGE.Run(PAGE::"Ins. Coverage Ledger Entries", InsCoverageLedgEntry);
    end;

    var
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
}

