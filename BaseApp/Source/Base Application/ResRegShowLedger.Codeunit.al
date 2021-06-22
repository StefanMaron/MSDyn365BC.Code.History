codeunit 275 "Res. Reg.-Show Ledger"
{
    TableNo = "Resource Register";

    trigger OnRun()
    begin
        ResLedgEntry.SetRange("Entry No.", "From Entry No.", "To Entry No.");
        PAGE.Run(PAGE::"Resource Ledger Entries", ResLedgEntry);
    end;

    var
        ResLedgEntry: Record "Res. Ledger Entry";
}

