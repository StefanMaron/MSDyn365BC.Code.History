codeunit 237 "G/L Reg.-Vend.Ledger"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        if GLEntry.Get("From Entry No.") then
            FromTransNo := GLEntry."Transaction No.";
        if GLEntry.Get("To Entry No.") then
            ToTransNo := GLEntry."Transaction No.";

        VendLedgEntry.SetRange("Transaction No.", FromTransNo, ToTransNo);
        VendLedgEntry.SetRange("Entry No.", "From Entry No.", "To Entry No.");
        PAGE.Run(PAGE::"Vendor Ledger Entries", VendLedgEntry);
    end;

    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        GLEntry: Record "G/L Entry";
        FromTransNo: Integer;
        ToTransNo: Integer;
}

