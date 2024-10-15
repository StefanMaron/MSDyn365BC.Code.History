codeunit 10143 "Deposit-Printed"
{
    Permissions = TableData "Posted Deposit Header" = rm;
    TableNo = "Posted Deposit Header";

    trigger OnRun()
    begin
        Find;
        "No. Printed" := "No. Printed" + 1;
        Modify;
        Commit();
    end;
}

