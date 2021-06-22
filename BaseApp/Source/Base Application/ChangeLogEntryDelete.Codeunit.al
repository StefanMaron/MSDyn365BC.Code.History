codeunit 510 "Change Log Entry - Delete"
{
    Permissions = TableData "Change Log Entry" = rid;
    TableNo = "Change Log Entry";

    trigger OnRun()
    begin
        Delete(true);
    end;
}

