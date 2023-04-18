codeunit 377 "G/L Reg.-Bank Account Ledger"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        BankAccLedgEntry.SetRange("Entry No.", "From Entry No.", "To Entry No.");
        PAGE.Run(PAGE::"Bank Account Ledger Entries", BankAccLedgEntry);
    end;

    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
}

