namespace Microsoft.Bank.Ledger;

using Microsoft.Finance.GeneralLedger.Ledger;

codeunit 377 "G/L Reg.-Bank Account Ledger"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        BankAccLedgEntry.SetRange("Entry No.", Rec."From Entry No.", Rec."To Entry No.");
        PAGE.Run(PAGE::"Bank Account Ledger Entries", BankAccLedgEntry);
    end;

    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
}

