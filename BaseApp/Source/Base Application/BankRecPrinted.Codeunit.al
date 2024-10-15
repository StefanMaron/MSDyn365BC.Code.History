codeunit 10124 "BankRec-Printed"
{
    Permissions = TableData "Posted Bank Rec. Header" = rm;
    TableNo = "Posted Bank Rec. Header";

    trigger OnRun()
    begin
        Find;
        "No. Printed" := "No. Printed" + 1;
        Modify;
        Commit;
    end;
}

