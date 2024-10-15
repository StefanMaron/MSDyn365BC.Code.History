codeunit 237 "G/L Reg.-Vend.Ledger"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        VendLedgEntry.SetCurrentKey("Transaction No.");
        VendLedgEntry.SetRange("Transaction No.", "No.");
        PAGE.Run(PAGE::"Vendor Ledger Entries", VendLedgEntry);
    end;

    var
        VendLedgEntry: Record "Vendor Ledger Entry";
}

