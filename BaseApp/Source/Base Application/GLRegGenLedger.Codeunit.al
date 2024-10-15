codeunit 235 "G/L Reg.-Gen. Ledger"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        GLEntry.SetCurrentKey("Transaction No.");
        GLEntry.SetRange("Transaction No.", "No.");
        PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
    end;

    var
        GLEntry: Record "G/L Entry";
}

