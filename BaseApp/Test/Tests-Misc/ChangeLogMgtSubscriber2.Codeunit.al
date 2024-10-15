codeunit 139133 "Change Log Mgt. Subscriber2"
{
    EventSubscriberInstance = manual;
    SingleInstance = true;

    trigger OnRun()
    begin
        // [FEATURE] [Change Log Extensions]
    end;

    var
        TableNo: Integer;

    procedure SetTableNo(NewTableNo: Integer)
    begin
        TableNo := NewTableNo;
    end;

    procedure GetTableNo(): Integer
    begin
        exit(TableNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Change Log Management", 'OnBeforeIsLogActive', '', true, true)]
    local procedure OnBeforeIsLogActive(TableNumber: Integer; FieldNumber: Integer; TypeOfChange: Option; var IsActive: Boolean; var IsHandled: Boolean)
    begin
        IsActive := TableNo = TableNumber;
        IsHandled := true;
    end;
}