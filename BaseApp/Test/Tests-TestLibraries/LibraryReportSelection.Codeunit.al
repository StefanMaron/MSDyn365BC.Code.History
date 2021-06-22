codeunit 131103 "Library - Report Selection"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

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
}

