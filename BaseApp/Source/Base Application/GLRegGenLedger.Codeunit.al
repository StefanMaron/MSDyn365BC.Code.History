codeunit 235 "G/L Reg.-Gen. Ledger"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        // GLEntry.SETRANGE("Entry No.","From Entry No.","To Entry No.");
        if "From Entry No." > 0 then
            GLEntry.SetRange("Entry No.", "From Entry No.", "To Entry No.")
        else
            GLEntry.SetRange("Entry No.", "To Entry No.", "From Entry No.");
        PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
    end;

    var
        GLEntry: Record "G/L Entry";
}

