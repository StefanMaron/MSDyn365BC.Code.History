codeunit 5779 "Whse.-Printed"
{
    TableNo = "Warehouse Activity Header";

    trigger OnRun()
    begin
        LockTable();
        Find();
        "No. Printed" := "No. Printed" + 1;
        "Date of Last Printing" := Today;
        "Time of Last Printing" := Time;
        OnBeforeModify(Rec);
        Modify();
        Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;
}

