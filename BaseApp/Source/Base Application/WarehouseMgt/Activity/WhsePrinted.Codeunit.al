namespace Microsoft.Warehouse.Activity;

codeunit 5779 "Whse.-Printed"
{
    TableNo = "Warehouse Activity Header";

    trigger OnRun()
    begin
        Rec.LockTable();
        Rec.Find();
        Rec."No. Printed" := Rec."No. Printed" + 1;
        Rec."Date of Last Printing" := Today;
        Rec."Time of Last Printing" := Time;
        OnBeforeModify(Rec);
        Rec.Modify();
        Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;
}

