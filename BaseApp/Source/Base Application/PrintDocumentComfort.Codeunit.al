codeunit 5005396 "Print Document Comfort"
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure DeliveryRemindPrint(DeliveryReminderHeader: Record "Delivery Reminder Header")
    var
        DACHReportSelections: Record "DACH Report Selections";
    begin
        DeliveryReminderHeader.SetRange("No.", DeliveryReminderHeader."No.");
        DACHReportSelections.SetRange(Usage, DACHReportSelections.Usage::"Delivery Reminder Test");
        DACHReportSelections.SetFilter("Report ID", '<>0');
        DACHReportSelections.Find('-');
        repeat
            REPORT.RunModal(DACHReportSelections."Report ID", true, false, DeliveryReminderHeader)
        until DACHReportSelections.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure IssuedDeliveryRemindPrint(IssuedDeliveryReminderHeader: Record "Issued Deliv. Reminder Header"; ShowRequestForm: Boolean)
    var
        DACHReportSelections: Record "DACH Report Selections";
    begin
        IssuedDeliveryReminderHeader.SetRange("No.", IssuedDeliveryReminderHeader."No.");
        DACHReportSelections.SetRange(Usage, DACHReportSelections.Usage::"Issued Delivery Reminder");
        DACHReportSelections.SetFilter("Report ID", '<>0');
        DACHReportSelections.Find('-');
        repeat
            REPORT.RunModal(DACHReportSelections."Report ID", ShowRequestForm, false, IssuedDeliveryReminderHeader)
        until DACHReportSelections.Next = 0;
    end;
}

