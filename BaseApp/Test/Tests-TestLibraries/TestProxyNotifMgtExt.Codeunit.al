codeunit 130232 "Test Proxy Notif. Mgt. Ext."
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 130231, 'OnCheckIgnoringNotification', '', false, false)]
    local procedure SetIgnoreOnCheckIgnoringNotification(NotificationID: Guid; var Ignore: Boolean)
    var
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
    begin
        Ignore := O365SalesInvoiceMgmt.GetTaxNotificationID = NotificationID;
    end;
}

