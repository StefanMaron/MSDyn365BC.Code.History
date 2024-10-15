codeunit 1368 "Monitored Field Notification"
{
    Access = Internal;

    procedure SendEmailNotificationOfSensitiveFieldChange(RecRef: RecordRef; FieldNo: integer; OriginalValue: Text; NewValue: Text; var MonitorFieldNotification: Enum "Monitor Field Notification")
    var
        FieldMonitoringSetup: record "Field Monitoring Setup";
        EmailMessage: Codeunit "Email Message";
        SendToList: List of [Text];
    begin
        if not IsMonitorReadyToSendEmails(FieldMonitoringSetup) then begin
            MonitorFieldNotification := MonitorFieldNotification::"Sending Email Failed";
            exit;
        end;

        SendToList.Add(GetRecipient());
        EmailMessage.CreateMessage(SendToList, GetEmailSubject(RecRef, FieldNo), GetEmailBody(RecRef, FieldNo, OriginalValue, NewValue), true);

        if Email.Send(EmailMessage.GetId(), FieldMonitoringSetup."Email Account Id", FieldMonitoringSetup."Email Connector") then
            MonitorFieldNotification := MonitorFieldNotification::"Email Sent"
        else
            MonitorFieldNotification := MonitorFieldNotification::"Sending Email Failed";
    end;

    local procedure IsMonitorReadyToSendEmails(var FieldMonitoringSetup: record "Field Monitoring Setup"): Boolean
    begin
        if FieldMonitoringSetup.Get() then
            if (FieldMonitoringSetup."Email Account Name" <> '') and (not IsNullGuid(FieldMonitoringSetup."Email Account Id")) and Email.IsAnyConnectorInstalled() then
                exit(true);
    end;

    local procedure GetRecipient(): Text
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        User: Record User;
    begin
        if FieldMonitoringSetup.Get() then begin
            user.SetRange("User Name", FieldMonitoringSetup."User Id");
            if User.FindFirst() then
                exit(User."Contact Email");
        end;
    end;

    local procedure GetEmailSubject(RecRef: RecordRef; FieldNo: integer): Text
    begin
        if IsMonitorStatusChange(RecRef, FieldNo) then
            if RecRef.Field(FieldNo).Value then
                exit(StrSubstNo(ChangeStateSubjMsg, MonitorEnabledTxt))
            else
                exit(StrSubstNo(ChangeStateSubjMsg, MonitorDisabledTxt));

        exit(StrSubstNo(ChangeStateSubjMsg, MonitorFieldChangeMsg));
    end;

    local procedure GetEmailBody(RecRef: RecordRef; FieldNo: integer; OriginalValue: Text; NewValue: Text): Text
    var
        LinkToRecord, LinkToEffectivePermission : Text;
    begin
        if IsMonitorStatusChange(RecRef, FieldNo) then
            if RecRef.Field(FieldNo).Value then
                exit(StrSubstNo(ChangeStateBodyMsg, CompanyName, MonitorDisabledTxt, MonitorEnabledTxt, UserId(), CurrentDateTime))
            else
                exit(StrSubstNo(ChangeStateBodyMsg, CompanyName, MonitorEnabledTxt, MonitorDisabledTxt, UserId(), CurrentDateTime));

        LinkToRecord := GetUrl(CurrentClientType, CompanyName, ObjectType::Page, page::"Monitored Field Log Entries");
        LinkToEffectivePermission := GetUrl(CurrentClientType, CompanyName, ObjectType::Page, page::"Effective Permissions");

        exit(StrSubstNo(FieldChangeBodyMsg, CompanyName, LinkToRecord, RecRef.Caption, RecRef.Field(FieldNo).Caption,
               OriginalValue, NewValue, UserId(), CurrentDateTime, LinkToEffectivePermission));
    end;

    local procedure IsMonitorStatusChange(RecRef: RecordRef; FieldNo: integer): Boolean
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
    begin
        exit((RecRef.Number = Database::"Field Monitoring Setup") and (FieldNo = FieldMonitoringSetup.FieldNo("Monitor Status")));
    end;

    var
        Email: Codeunit Email;
        ChangeStateSubjMsg: Label 'Business Central Extended Security - %1', Comment = '%1 is started or stopped as see in MonitorEnabledTxt,MonitorDisabledTxt labels';
        ChangeStateBodyMsg: Label '<p style="font-family:Verdana,Arial;font-size:10pt"><b>You are signed up to receive email notifications when certain data is changed in the %1 company in Microsoft Dynamics 365 Business Central. <BR>This message is to inform you that the following change was made:</b></p><p style="font-family:Verdana,Arial;font-size:9pt"><b>Extended Security State has changed:</b><BR><b>Original State:</b> %2<BR><b>New State:</b> %3<BR><b>Changed By:</b> %4<BR><b>Changed Date/Time:</b> %5</p><p>Notification messages are sent automatically and cannot be replied to.</p>',
        Comment = '{Locked="p style=","font-family:","font-size","pt","<b>","</b>","</p>","<BR>","SMTP"} %1 is Company Name; %2 is original state, started or stopped; %3 is new state, started or stopped; %4 is Changed By, User who made the change; %5  date time';
        MonitorEnabledTxt: Label 'Started';
        MonitorDisabledTxt: Label 'Stopped';
        MonitorFieldChangeMsg: Label 'Monitored Change Notification';
        FieldChangeBodyMsg: Label '<p style="font-family:Verdana,Arial;font-size:10pt"><b>You are signed up to receive email notifications when certain data is changed in the %1 company in Microsoft Dynamics 365 Business Central. <BR>This message is to inform you that the following change was made:</b></p><p style="font-family:Verdana,Arial;font-size:9pt"><b><BR>Extended Security has detected a <a href="%2">change</a> in a %3 field marked for monitoring:</b><BR><b>Original "%4" Value:</b> %5<BR><b>New "%4" Value:</b> %6<BR><b>Changed By:</b> %7<BR><b>Changed Date/Time:</b> %8<BR></p><p><a href="%9">Effective permissions</a> for user %7 allowed for this change.</p><p>Notification messages are sent automatically and cannot be replied to.</p>',
        Comment = '{Locked="p style=","font-family:","font-size","pt","<b>","</b>","</p>","<BR>","SMTP"} %1 is Company Name;%2 Link, example https://Businesscentral.com/?page=1; %3 table caption; %4 field caption; %5 is original state, started or stopped; %6 is new state, started or stopped; %7 is Changed By, User who made the change; %8  date time;%9 Link to effective permission page';
}