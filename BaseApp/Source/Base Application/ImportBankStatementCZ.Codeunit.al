codeunit 11718 "Import Bank Statement CZ"
{
    TableNo = "Bank Acc. Reconciliation";

    trigger OnRun()
    begin
        ImportBankStatement;
    end;
}

