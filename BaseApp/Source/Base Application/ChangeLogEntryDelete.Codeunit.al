codeunit 510 "Change Log Entry - Delete"
{
    Permissions = TableData "Change Log Entry" = rid;
    TableNo = "Change Log Entry";
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality has been replaced with the retention policy module in system application.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
        SetRange("Field Log Entry Feature", "Field Log Entry Feature"::"Change Log");
        Delete(true);
    end;
}

