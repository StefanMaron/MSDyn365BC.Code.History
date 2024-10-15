codeunit 236 "G/L Reg.-Cust.Ledger"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        CustLedgEntry.SetCurrentKey("Transaction No.");
        CustLedgEntry.SetRange("Transaction No.", "No.");
        PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgEntry);
    end;

    var
        CustLedgEntry: Record "Cust. Ledger Entry";
}

