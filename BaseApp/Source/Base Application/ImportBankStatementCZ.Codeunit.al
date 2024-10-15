#if not CLEAN19
codeunit 11718 "Import Bank Statement CZ"
{
    TableNo = "Bank Acc. Reconciliation";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    trigger OnRun()
    begin
        ImportBankStatement;
    end;
}

#endif