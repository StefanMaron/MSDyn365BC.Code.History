codeunit 236 "G/L Reg.-Cust.Ledger"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        if GLEntry.Get("From Entry No.") then
            FromTransNo := GLEntry."Transaction No.";
        if GLEntry.Get("To Entry No.") then
            ToTransNo := GLEntry."Transaction No.";

        CustLedgEntry.SetRange("Transaction No.", FromTransNo, ToTransNo);
        PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgEntry);
    end;

    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
        FromTransNo: Integer;
        ToTransNo: Integer;
}

