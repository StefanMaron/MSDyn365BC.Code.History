codeunit 131103 "Library - Report Selection"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        EventHandledName: Text;

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnBeforeSendEmailToCust', '', false, false)]
    local procedure HandleOnBeforeSendEmailToCust(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ShowDialog: Boolean; CustNo: Code[20]; var Handled: Boolean)
    begin
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnBeforeSendEmailToVendor', '', false, false)]
    local procedure HandleOnBeforeSendEmailToVendor(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ShowDialog: Boolean; VendorNo: Code[20]; var Handled: Boolean)
    begin
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Warehouse Document-Print", 'OnBeforePrintPickHeader', '', false, false)]
    local procedure HandleOnBeforePrintPickHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
        IsHandled := true;
        EventHandledName := 'HandleOnBeforePrintPickHeader';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Warehouse Document-Print", 'OnBeforePrintPutAwayHeader', '', false, false)]
    local procedure HandleOnBeforePrintPutAwayHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
        IsHandled := true;
        EventHandledName := 'HandleOnBeforePrintPutAwayHeader';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Warehouse Document-Print", 'OnBeforePrintMovementHeader', '', false, false)]
    local procedure HandleOnBeforePrintMovementHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
        IsHandled := true;
        EventHandledName := 'HandleOnBeforePrintMovementHeader';
    end;

    [Scope('OnPrem')]
    procedure GetEventHandledName(): Text
    begin
        exit(EventHandledName);
    end;
}

