codeunit 5005396 "Print Document Comfort"
{

    trigger OnRun()
    begin
    end;

    procedure DeliveryRemindPrint(DeliveryReminderHeader: Record "Delivery Reminder Header")
    var
        DACHReportSelections: Record "DACH Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeliveryRemindPrint(DeliveryReminderHeader, IsHandled);
        if IsHandled then
            exit;

        DeliveryReminderHeader.SetRange("No.", DeliveryReminderHeader."No.");
        DACHReportSelections.SetRange(Usage, DACHReportSelections.Usage::"Delivery Reminder Test");
        DACHReportSelections.SetFilter("Report ID", '<>0');
        OnDeliveryRemindPrintOnAfterSetFilters(DACHReportSelections, DeliveryReminderHeader);
        DACHReportSelections.Find('-');
        repeat
            REPORT.RunModal(DACHReportSelections."Report ID", true, false, DeliveryReminderHeader)
        until DACHReportSelections.Next() = 0;
    end;

    procedure IssuedDeliveryRemindPrint(IssuedDeliveryReminderHeader: Record "Issued Deliv. Reminder Header"; ShowRequestForm: Boolean)
    var
        DACHReportSelections: Record "DACH Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIssuedDeliveryRemindPrint(IssuedDeliveryReminderHeader, ShowRequestForm, IsHandled);
        if IsHandled then
            exit;

        IssuedDeliveryReminderHeader.SetRange("No.", IssuedDeliveryReminderHeader."No.");
        DACHReportSelections.SetRange(Usage, DACHReportSelections.Usage::"Issued Delivery Reminder");
        DACHReportSelections.SetFilter("Report ID", '<>0');
        DACHReportSelections.Find('-');
        repeat
            REPORT.RunModal(DACHReportSelections."Report ID", ShowRequestForm, false, IssuedDeliveryReminderHeader)
        until DACHReportSelections.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeliveryRemindPrint(var DeliveryReminderHeader: Record "Delivery Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssuedDeliveryRemindPrint(var IssuedDeliveryReminderHeader: Record "Issued Deliv. Reminder Header"; var ShowRequestForm: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeliveryRemindPrintOnAfterSetFilters(var DACHReportSelections: Record "DACH Report Selections"; var DeliveryReminderHeader: Record "Delivery Reminder Header")
    begin
    end;
}

