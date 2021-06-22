codeunit 5619 "G/L Reg.-FALedger"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        FALedgEntry.SetCurrentKey("G/L Entry No.");
        FALedgEntry.SetRange("G/L Entry No.", "From Entry No.", "To Entry No.");
        PAGE.Run(PAGE::"FA Ledger Entries", FALedgEntry);
    end;

    var
        FALedgEntry: Record "FA Ledger Entry";
}

