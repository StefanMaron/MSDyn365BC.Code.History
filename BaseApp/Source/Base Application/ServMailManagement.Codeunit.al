codeunit 5916 ServMailManagement
{
    TableNo = "Service Email Queue";

    trigger OnRun()
    var
        TempEmailItem: Record "Email Item" temporary;
        MailManagement: Codeunit "Mail Management";
        EmailFeature: Codeunit "Email Feature";
    begin
        if EmailFeature.IsEnabled() then begin
            // do not silently exit if the sending failed
            if not MailManagement.IsEnabled() then
                Error(EmailSendErr, "To Address", "Subject Line")
        end else
            if not MailManagement.IsEnabled() then
                exit;

        InitTempEmailItem(TempEmailItem, Rec);

        MailManagement.SetHideMailDialog(true);
        MailManagement.SetHideEmailSendingError(false);
        if not MailManagement.Send(TempEmailItem, Enum::"Email Scenario"::"Service Order") then
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

