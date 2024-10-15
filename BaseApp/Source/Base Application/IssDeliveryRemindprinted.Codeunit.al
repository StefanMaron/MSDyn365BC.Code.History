codeunit 5005273 "Iss. Delivery Remind. printed"
{
    Permissions = TableData "Issued Deliv. Reminder Header" = rimd;
    TableNo = "Issued Deliv. Reminder Header";

    trigger OnRun()
    begin
        Find;
        "No. Printed" := "No. Printed" + 1;
        OnRunOnBeforeModify(Rec);
        Modify;
        Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeModify(var IssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header")
    begin
    end;
}

