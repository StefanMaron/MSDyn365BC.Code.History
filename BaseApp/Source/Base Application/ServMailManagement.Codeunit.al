codeunit 5916 ServMailManagement
{
    TableNo = "Service Email Queue";

    trigger OnRun()
    var
        TempEmailItem: Record "Email Item" temporary;
        MailManagement: Codeunit "Mail Management";
    begin
        if not MailManagement.IsEnabled then
            exit;

        InitTempEmailItem(TempEmailItem, Rec);

        MailManagement.SetHideMailDialog(true);
        MailManagement.SetHideSMTPError(false);
        if not MailManagement.Send(TempEmailItem) then
            Error(EmailSendErr, "To Address", "Subject Line");
    end;

    var
        EmailSendErr: Label 'The email to %1 with subject %2 has not been sent.', Comment = '%1 - To address, %2 - Email subject';

    local procedure InitTempEmailItem(var TempEmailItem: Record "Email Item" temporary; ServiceEmailQueue: Record "Service Email Queue")
    begin
        with ServiceEmailQueue do begin
            TempEmailItem.Initialize;
            TempEmailItem."Attachment File Path" := "Attachment Filename";
            TempEmailItem.SetBodyText("Body Line");
            TempEmailItem."Send to" := "To Address";
            TempEmailItem."Send CC" := "Copy-to Address";
            TempEmailItem.Subject := "Subject Line";
            TempEmailItem.Insert();
        end;
    end;
}

