codeunit 235 "G/L Reg.-Gen. Ledger"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        GLEntry.SetRange("Entry No.", "From Entry No.", "To Entry No.");
        PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
    end;

    var
        GLEntry: Record "G/L Entry";
}

