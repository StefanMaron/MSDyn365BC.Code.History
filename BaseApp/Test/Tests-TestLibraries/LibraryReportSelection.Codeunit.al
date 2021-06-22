codeunit 131103 "Library - Report Selection"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        EventHandledName: Text;

    [EventSubscriber(ObjectType::Table, 77, 'OnBeforeSendEmailToCust', '', false, false)]
    local procedure HandleOnBeforeSendEmailToCust(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ShowDialog: Boolean; CustNo: Code[20]; var Handled: Boolean)
    begin
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Table, 77, 'OnBeforeSendEmailToVendor', '', false, false)]
    local procedure HandleOnBeforeSendEmailToVendor(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ShowDialog: Boolean; VendorNo: Code[20]; var Handled: Boolean)
    begin
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5776, 'OnBeforePrintPickHeader', '', false, false)]
    local procedure HandleOnBeforePrintPickHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
        IsHandled := true;
        EventHandledName := 'HandleOnBeforePrintPickHeader';
    end;

    [EventSubscriber(ObjectType::Codeunit, 5776, 'OnBeforePrintPutAwayHeader', '', false, false)]
    local procedure HandleOnBeforePrintPutAwayHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
        IsHandled := true;
        EventHandledName := 'HandleOnBeforePrintPutAwayHeader';
    end;

    [EventSubscriber(ObjectType::Codeunit, 5776, 'OnBeforePrintMovementHeader', '', false, false)]
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

