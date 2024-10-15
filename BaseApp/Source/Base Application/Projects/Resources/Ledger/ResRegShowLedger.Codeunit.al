namespace Microsoft.Projects.Resources.Ledger;

codeunit 275 "Res. Reg.-Show Ledger"
{
    TableNo = "Resource Register";

    trigger OnRun()
    begin
        ResLedgEntry.SetRange("Entry No.", Rec."From Entry No.", Rec."To Entry No.");
        PAGE.Run(PAGE::"Resource Ledger Entries", ResLedgEntry);
    end;

    var
        ResLedgEntry: Record "Res. Ledger Entry";
}

