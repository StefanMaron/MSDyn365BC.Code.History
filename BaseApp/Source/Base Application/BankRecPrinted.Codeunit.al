#pragma warning disable AS0074
#if not CLEAN21
codeunit 10124 "BankRec-Printed"
{
    Permissions = TableData "Posted Bank Rec. Header" = rm;
    TableNo = "Posted Bank Rec. Header";
    ObsoleteReason = 'Deprecated in favor of W1 Bank Reconciliation';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    trigger OnRun()
    begin
        Find();
        "No. Printed" := "No. Printed" + 1;
        Modify();
        Commit();
    end;
}

#endif
#pragma warning restore AS0074