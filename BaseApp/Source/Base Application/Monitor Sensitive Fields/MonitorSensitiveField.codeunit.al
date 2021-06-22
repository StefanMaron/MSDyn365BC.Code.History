codeunit 1392 "Monitor Sensitive Field"
{
    Permissions = tabledata "Field Monitoring Setup" = im;

    procedure ValidateTableNo(TableNo: Integer)
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        if not IsValidTable(TableNo) then
            Error(SystemTableErr);

        ChangeLogSetupTable.SetRange("Monitor Sensitive Field", false);
        ChangeLogSetupTable.SetRange("Table No.", TableNo);
        if not ChangeLogSetupTable.IsEmpty() then
            Error(TableMonitoredInChangeLogErr);
    end;

    procedure ValidateTableAndFieldNo(TableNo: Integer; FieldNo: Integer)
    begin
        ValidateTableNo(TableNo);

        if not IsValidField(TableNo, FieldNo) then
            Error(ValidTableAndFieldErr);
    end;

    procedure InsertChangeLogSetupTable(TableNo: Integer)
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        if not ChangeLogSetupTable.Get(TableNo) then begin
            ChangeLogSetupTable.Validate("Table No.", TableNo);
            ChangeLogSetupTable.Validate("Monitor Sensitive Field", true);
            ChangeLogSetupTable."Log Insertion" := ChangeLogSetupTable."Log Insertion"::"Some Fields";
            ChangeLogSetupTable."Log Modification" := ChangeLogSetupTable."Log Modification"::"Some Fields";
            ChangeLogSetupTable."Log Deletion" := ChangeLogSetupTable."Log Deletion"::"Some Fields";
            ChangeLogSetupTable.Insert(true);
        end;
    end;

    procedure DeleteChangeLogSetupTable(TableNo: integer; FieldNo: Integer)
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        ChangeLogSetupField: Record "Change Log Setup (Field)";
    begin
        ChangeLogSetupField.SetRange("Table No.", TableNo);
        ChangeLogSetupField.SetFilter("Field No.", '<>%1', FieldNo);

        if ChangeLogSetupField.IsEmpty() then begin
            ChangeLogSetupTable.Get(TableNo);
            ChangeLogSetupTable.Delete();
        end;
    end;

    procedure GetTableCaption(TableNo: Integer): Text
    var
        AllObj: Record AllObjWithCaption;
    begin
        AllObj.Get(AllObj."Object Type"::Table, TableNo);
        exit(AllObj."Object Caption");
    end;

    procedure GetNotificationCount(): integer
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
    begin
        if FieldMonitoringSetup.Get() then
            exit(FieldMonitoringSetup."Notification Count");
    end;

    procedure OpenDataSensitivityFilterPage()
    var
        DataSensitivity: Record "Data Sensitivity";
        FilterPageBuilder: FilterPageBuilder;
    begin
        FilterPageBuilder.PageCaption(PageCaptionTxt);
        FilterPageBuilder.AddTable(DataSensitivity.TableCaption(), Database::"Data Sensitivity");
        FilterPageBuilder.AddFieldNo(DataSensitivity.TableCaption(), DataSensitivity.FieldNo("Data Sensitivity"));
        FilterPageBuilder.AddFieldNo(DataSensitivity.TableCaption(), DataSensitivity.FieldNo("Table Caption"));
        FilterPageBuilder.AddFieldNo(DataSensitivity.TableCaption(), DataSensitivity.FieldNo("Field Caption"));

        if FilterPageBuilder.RunModal() then begin
            DataSensitivity.SetView(FilterPageBuilder.GetView(DataSensitivity.TableCaption));
            ImportMonitorFieldsByDataSensitivity(DataSensitivity);
        end;
    end;

    procedure AddAllowedFieldFilters(var FieldTable: Record Field)
    begin
        FieldTable.SetRange(Class, FieldTable.Class::Normal);
        FieldTable.SetFilter(Type, StrSubstNo(FieldFilterTxt,
                FieldTable.Type::Boolean,
                FieldTable.Type::Text,
                FieldTable.Type::Code,
                FieldTable.Type::Decimal,
                FieldTable.Type::Integer,
                FieldTable.Type::BigInteger,
                FieldTable.Type::Date,
                FieldTable.Type::Time,
                FieldTable.Type::DateTime,
                FieldTable.Type::DateFormula,
                FieldTable.Type::Option,
                FieldTable.Type::Duration,
                FieldTable.Type::GUID));
        FieldTable.SetFilter("No.", '<2000000000');
    end;

    procedure AddValidTablesFilter(var AllObjWithCaption: Record AllObjWithCaption)
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetFilter("Object ID", TableIdFilter());
    end;

    procedure EnableMonitor(ShowConfirmMessage: Boolean)
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
    begin
        GetSetupTable(FieldMonitoringSetup);

        if FieldMonitoringSetup."Email Account Name" = '' then
            Error(EmailAccountMissingErr);

        if FieldMonitoringSetup."Monitor Status" then
            exit;

        CheckUserHasValidContactEmail(FieldMonitoringSetup."User Id");

        if ShowConfirmMessage then
            if not Confirm(ConfirmEnableQst) then
                error('');

        SetMonitorStatus(FieldMonitoringSetup, true);
    end;

    procedure DisableMonitor()
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
    begin
        GetSetupTable(FieldMonitoringSetup);
        if FieldMonitoringSetup."Monitor Status" = false then
            exit;

        SetMonitorStatus(FieldMonitoringSetup, false);
    end;

    procedure CheckUserHasValidContactEmail(MonitorUserId: Code[50])
    var
        User: record User;
    begin
        if MonitorUserId = '' then
            Error(UserNotFoundErr);

        User.SetRange("User Name", MonitorUserId);
        if not User.FindFirst() then
            Error(UserNotFoundErr);

        ShowUserCardIfMissingContactEmail(User);
    end;

    procedure ExcludeMonitorTablesFromChangeLog(var AllObjectWithCaption: Record AllObjWithCaption)
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        if AllObjectWithCaption.FindSet() then
            repeat
                if not ChangeLogSetupTable.Get(AllObjectWithCaption."Object ID") then
                    AllObjectWithCaption.Mark(true)
                else
                    if not ChangeLogSetupTable."Monitor Sensitive Field" then
                        AllObjectWithCaption.Mark(true);
            until AllObjectWithCaption.Next() = 0;

        AllObjectWithCaption.MarkedOnly(true);

        ChangeLogSetupTable.Init();
        ChangeLogSetupTable.SetRange("Monitor Sensitive Field", true);
        if not ChangeLogSetupTable.IsEmpty then
            ShowChangeLogHiddenTablesNotification();
    end;

    procedure GetSetupTable(var FieldMonitoringSetup: Record "Field Monitoring Setup")
    begin
        if not FieldMonitoringSetup.Get() then
            FieldMonitoringSetup.Insert(false);
    end;

    procedure AddMonitoredField(TableNo: Integer; FieldNo: Integer; Notify: Boolean)
    var
        ChangeLogSetupField: record "Change Log Setup (Field)";
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        if not IsValidTableAndField(TableNo, FieldNo) then
            exit;

        ChangeLogSetupTable.SetRange("Monitor Sensitive Field", false);
        ChangeLogSetupTable.SetRange("Table No.", TableNo);
        if not ChangeLogSetupTable.IsEmpty() then
            exit;

        if not ChangeLogSetupField.Get(TableNo, FieldNo) then begin
            InsertChangeLogSetupTable(TableNo);

            ChangeLogSetupField.Validate("Table No.", TableNo);
            ChangeLogSetupField.Validate("Field No.", FieldNo);
            ChangeLogSetupField.Validate(Notify, Notify);
            ChangeLogSetupField.Validate("Monitor Sensitive Field", true);
            ChangeLogSetupField.validate("Log Deletion", true);
            ChangeLogSetupField.Validate("Log Insertion", true);
            ChangeLogSetupField.Validate("Log Modification", true);
            ChangeLogSetupField.Insert();
        end;
    end;

    procedure ImportFieldsBySensitivity(Sensitive: Boolean; Personal: Boolean; CompanyConfidential: Boolean)
    var
        DataSensitivity: Record "Data Sensitivity";
        FilterString: Text;
    begin
        if Sensitive then
            AddFilter(FilterString, format(DataSensitivity."Data Sensitivity"::Sensitive));
        if Personal then
            AddFilter(FilterString, format(DataSensitivity."Data Sensitivity"::Personal));
        if CompanyConfidential then
            AddFilter(FilterString, format(DataSensitivity."Data Sensitivity"::"Company Confidential"));
        DataSensitivity.SetFilter("Data Sensitivity", FilterString);

        ImportMonitorFieldsByDataSensitivity(DataSensitivity);
    end;

    procedure SetSetupTable(MonitorUserId: text[50]; EmailAccountId: Guid; EmailAccountName: Text[250]; EmailConnector: Enum "Email Connector")
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
    begin
        GetSetupTable(FieldMonitoringSetup);
        FieldMonitoringSetup.validate("User Id", MonitorUserId);
        FieldMonitoringSetup.Validate("Email Account Id", EmailAccountId);
        FieldMonitoringSetup.Validate("Email Account Name", EmailAccountName);
        FieldMonitoringSetup.Validate("Email Connector", EmailConnector);
        FieldMonitoringSetup.Modify();
    end;

    procedure ShowPromoteMonitorSensitiveFieldNotification()
    var
        PromoteMonitorSensitiveFieldNotification: Notification;
    begin
        if not EmailFeature.IsEnabled() then
            exit;
            
        if IsMonitorEnabled() then
            exit;

        if not IsNotificationEnabled(GetPromoteMonitorFeatureNotificationId()) then
            exit;
        PromoteMonitorSensitiveFieldNotification.AddAction(EnableFieldMonitoringMsg, CODEUNIT::"Monitor Sensitive Field", 'OpenFieldMonitoringSetup');
        CreateNotification(PromoteMonitorSensitiveFieldNotification, GetPromoteMonitorFeatureNotificationId(), PromoteMonitorFeatureMsg, NotificationScope::LocalScope);
        PromoteMonitorSensitiveFieldNotification.Send();
    end;

    procedure OpenFieldMonitoringSetup(notification: Notification)
    begin
        Page.Run(Page::"Monitor Field Setup Wizard");
    end;

    procedure OpenFieldMonitoringWorksheet(notification: Notification)
    begin
        Page.Run(Page::"Monitored Fields Worksheet");
    end;

    local procedure ShowChangeLogHiddenTablesNotification()
    var
        ChangeLogHiddenTableNotification: Notification;
    begin
        if not IsNotificationEnabled(GetChangeLogHiddenTablesNotificationId()) then
            exit;

        ChangeLogHiddenTableNotification.AddAction(OpenWorksheetMsg, CODEUNIT::"Monitor Sensitive Field", 'OpenFieldMonitoringWorksheet');
        CreateNotification(ChangeLogHiddenTableNotification, GetChangeLogHiddenTablesNotificationId(), HiddenTablesNotificationMsg, NotificationScope::LocalScope);
        ChangeLogHiddenTableNotification.Send();
    end;

    local procedure IsMonitorEnabled(): Boolean
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
    begin
        if not FieldMonitoringSetup.Get() then
            exit(false);
        exit(FieldMonitoringSetup."Monitor Status");
    end;

    local procedure CreateNotification(var MonitorNotification: Notification; Id: Text; Message: Text; MonitorNotificationScope: NotificationScope)
    begin
        MonitorNotification.Id := Id;
        MonitorNotification.Message(Message);
        MonitorNotification.Scope(MonitorNotificationScope);
        MonitorNotification.AddAction(DontShowThisAgainMsg, CODEUNIT::"Monitor Sensitive Field", 'DisableNotification');
    end;

    procedure DisableNotification(Notification: notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        case Notification.Id of
            GetChangeLogHiddenTablesNotificationId():
                MyNotifications.InsertDefault(Notification.Id, HiddenTablesNotificationNameTok,
                  HiddenTablesNotificationDescTok, false);
            GetPromoteMonitorFeatureNotificationId():
                MyNotifications.InsertDefault(Notification.Id, PromoteMonitorFeatureNotificationNameTok,
                  PromoteMonitorFeatureNotificationDescTok, false);
        end;

        MyNotifications.Disable(Notification.Id)
    end;

    local procedure IsNotificationEnabled(NotificationId: Guid): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(MyNotifications.IsEnabled(NotificationId));
    end;

    local procedure ImportMonitorFieldsByDataSensitivity(var DataSensitivity: Record "Data Sensitivity")
    begin
        if DataSensitivity.GetFilters = '' then
            exit;

        if DataSensitivity.FindSet() then
            repeat
                AddMonitoredField(DataSensitivity."Table No", DataSensitivity."Field No", false);
            until DataSensitivity.Next() = 0;
    end;

    local procedure IsValidTableAndField(TableNo: Integer; FieldNo: Integer): Boolean
    begin
        if not IsValidTable(TableNo) then
            exit(false);

        if not IsValidField(TableNo, FieldNo) then
            exit(false);

        exit(true);
    end;

    procedure IsValidTable(TableNo: Integer): Boolean
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.FilterGroup := 10;
        AllObjWithCaption.Setrange("Object ID", TableNo);
        AllObjWithCaption.Setrange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.FilterGroup := 11;
        AllObjWithCaption.SetFilter("Object ID", TableIdFilter());
        exit(not AllObjWithCaption.IsEmpty());
    end;

    local procedure IsValidField(TableNo: Integer; FieldNo: Integer): Boolean
    var
        FieldTable: Record Field;
    begin
        FieldTable.SetRange(TableNo, TableNo);
        FieldTable.SetRange("No.", FieldNo);
        AddAllowedFieldFilters(FieldTable);
        if not FieldTable.IsEmpty() then
            exit(true);
    end;

    local procedure TableIdFilter(): Text
    begin
        // Exclude Change log tables: 402..405
        // Exclude Monitor sensitive field tables 1366
        // Exclude email system module tables: Email Outbox: 8888, Sent Email:8889, Email Message: 8900,Email Error:8901, Email Recipient:8903,  Email message Attachment: 8904
        exit(StrSubstNo(TableNoFilterTxt, 401, 406, 1365, 1367, 8887, 8890, 8899, 8902, 8905, Database::User, Database::"Data Sensitivity"));
    end;

    local procedure ShowUserCardIfMissingContactEmail(User: Record User)
    begin
        if User."Contact Email" = '' then begin
            if Confirm(UserMissingContactEmailQst) then
                Page.Run(Page::"User Card", User);
            Error('');
        end;
    end;

    local procedure SetMonitorStatus(var FieldMonitoringSetup: Record "Field Monitoring Setup"; Status: Boolean)
    var
        Attributes: Dictionary of [Text, Text];
    begin
        FieldMonitoringSetup."Monitor Status" := Status;
        FieldMonitoringSetup.Modify();

        Attributes.Add('monitorStatus', Format(Status));
        Session.LogMessage('0000DD3', StrSubstNo(MonitorStatusChangeTxt, Format(Status)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Attributes);
    end;

    procedure ValidateUserPermissions(MonitorUserId: Code[50]; var DoesUserHasPermission: Boolean)
    var
        Permission: Record Permission;
        User: Record User;
    begin
        User.SetRange("User Name", MonitorUserId);
        User.FindFirst();

        DoesUserHasPermission := CheckPermission(User, Database::"Field Monitoring Setup", Permission."Read Permission"::Yes, Permission."Insert Permission"::Indirect,
            Permission."Modify Permission"::Yes, Permission."Delete Permission"::Indirect);
    end;

    procedure OpenUserCard(MonitorUserId: code[250])
    var
        User: Record User;
    begin
        User.SetRange("User Name", MonitorUserId);
        User.FindFirst();
        Page.Run(Page::"User Card", User);
    end;

    procedure GetPromoteMonitorFeatureNotificationId(): Guid
    begin
        exit(PromoteMonitorFeatureNotificationIdTxt);
    end;

    procedure GetChangeLogHiddenTablesNotificationId(): Guid
    begin
        exit(ChangeLogHiddenTablesNotificationIdTxt);
    end;

    local procedure CheckPermission(User: Record User; TableNo: Integer; ReadPermission: Option " ",Yes,Indirect; InsertPermission: Option " ",Yes,Indirect; ModifyPermission: Option " ",Yes,Indirect; DeletePermission: Option " ",Yes,Indirect): Boolean
    var
        Permission: Record Permission;
        EffectivePermissions: Codeunit "Effective Permissions Mgt.";
    begin
        EffectivePermissions.PopulatePermissionRecordWithEffectivePermissionsForObject(Permission, User."User Security ID",
           CopyStr(CompanyName(), 1, 50), Permission."Object Type"::"Table Data", TableNo);
        exit((Permission."Read Permission" = ReadPermission) and (Permission."Insert Permission" = InsertPermission) and
            (Permission."Modify Permission" = ModifyPermission) and (Permission."Delete Permission" = DeletePermission));
    end;

    local procedure AddFilter(var FilterString: Text; NewFilter: Text)
    begin
        if FilterString = '' then
            FilterString := NewFilter
        else
            FilterString := FilterString + '|' + NewFilter;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assisted Setup", 'OnRegister', '', false, false)]
    local procedure AddMonitorFieldSetupWizard()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        Language: Codeunit Language;
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        Info: ModuleInfo;
        CurrentGlobalLanguage: Integer;
    begin
        if not EmailFeature.IsEnabled() then
            exit;

        NavApp.GetCurrentModuleInfo(Info);
        CurrentGlobalLanguage := GLOBALLANGUAGE();

        AssistedSetup.Add(Info.Id(), Page::"Monitor Field Setup Wizard", MonitorSetupTxt, AssistedSetupGroup::"Set Up Extended Security", '', VideoCategory::Uncategorized, HelpMonitorFieldChangeTxt, HelpMonitorDescriptionTxt);

        GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
        AssistedSetup.AddTranslation(Page::"Monitor Field Setup Wizard", Language.GetDefaultApplicationLanguageId(), MonitorSetupTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);
    end;

    var
        EmailFeature: Codeunit "Email Feature";
        PageCaptionTxt: Label 'Add Fields To Monitor Fields Worksheet';
        SystemTableErr: Label 'You cannot monitor fields on the specified table. For example, the table ID might not exist or it might be a system table.';
        TableMonitoredInChangeLogErr: Label 'This table is monitored in Change log. If you want to monitor it here, please remove it from change log setup.';
        ValidTableAndFieldErr: Label 'You must choose a valid table and field. Field can not be blob, media or media set.';
        FieldFilterTxt: Label '%1|%2|%3|%4|%5|%6|%7|%8|%9|%10|%11|%12|%13', Locked = true;
        UserNotFoundErr: Label 'To start monitoring fields, you must specify the user who will receive notification emails when field values change.';
        UserMissingContactEmailQst: Label 'A contact email address is not specified for the user. Do you want to open the User page to set that up for the user now?';
        ConfirmEnableQst: Label 'Monitoring fields can impact performance. We recommend that you only monitor fields that contain sensitive data.';
        MonitorStatusChangeTxt: Label 'Sensitive field monitor status has changed to %1', Locked = true;
        TableNoFilterTxt: Label '1..%1|%2..%3|%4..%5|%6..%7|%8|%9..1999999999|%10|%11', Locked = true;
        EmailAccountMissingErr: label 'To start monitoring fields, you must specify the email account to send notification emails from when field values change.';
        MonitorSetupTxt: Label 'Monitor Field Change Setup';
        HelpMonitorFieldChangeTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2128531', Locked = true;
        HelpMonitorDescriptionTxt: Label 'Set up monitor field change feature';
        DontShowThisAgainMsg: Label 'Don''t show this again.';
        EnableFieldMonitoringMsg: Label 'Enable Field Monitoring';
        OpenWorksheetMsg: Label 'Open the Monitored Fields Worksheet';
        HiddenTablesNotificationMsg: Label 'Some tables are hidden because they are contain fields that are being monitored for changes.';
        PromoteMonitorFeatureMsg: Label 'This page contains sensitive business data. You can set up a notification to alert you when data changes.';
        HiddenTablesNotificationNameTok: Label 'Notify users about hidden tables in the Change Log Setup.';
        HiddenTablesNotificationDescTok: Label 'Notify users that some tables are hidden in the Change Log Table List page because they contain fields that are being monitored for changes.';
        PromoteMonitorFeatureNotificationNameTok: Label 'Notify users about monitoring sensitive data';
        PromoteMonitorFeatureNotificationDescTok: Label 'Notify users about hidden tables in the Change Log setup.';
        ChangeLogHiddenTablesNotificationIdTxt: Label '2e7fe3ad-6382-4cbd-93f8-79bad5b53854';
        PromoteMonitorFeatureNotificationIdTxt: Label '6a2fe3ad-6382-4acd-34f8-7dbad5b51245';
}