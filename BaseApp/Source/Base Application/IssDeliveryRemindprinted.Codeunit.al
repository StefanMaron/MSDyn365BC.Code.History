codeunit 5005273 "Iss. Delivery Remind. printed"
{
    Permissions = TableData "Issued Deliv. Reminder Header" = rimd;
    TableNo = "Issued Deliv. Reminder Header";

    trigger OnRun()
    begin
        Find;
        "No. Printed" := "No. Printed" + 1;
        Modify;
        Commit;
    end;
}

