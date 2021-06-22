codeunit 1367 "Monitor Sensitive Field Data"
{
    Permissions = tabledata "Field Monitoring Setup" = im;

    procedure CheckIfTableIsMonitored(var TempChangeLogSetupTable: Record "Change Log Setup (Table)" temporary; FieldMonitoringSetup: Record "Field Monitoring Setup"; ChangeLogSetup: Record "Change Log Setup"): Boolean
    begin
        if TempChangeLogSetupTable."Monitor Sensitive Field" then
            exit(FieldMonitoringSetup."Monitor Status")
        else
            exit(ChangeLogSetup."Change Log Activated")
    end;

    procedure HandleMonitorSensitiveFields(var ChangeLogEntry: Record "Change Log Entry"; var TempChangeLogSetupField: Record "Change Log Setup (Field)" temporary; RecRef: RecordRef; FldRef: FieldRef; IsAlwaysLoggedTable: Boolean; IsMonitorEnabled: Boolean)
    var
        MonitorFieldNotification: Enum "Monitor Field Notification";
        Attributes: Dictionary of [Text, Text];
        IsAlwaysLoggedMonitorTableActive, IsMonitoredFieldActive : Boolean;
    begin
        IsAlwaysLoggedMonitorTableActive := IsAlwaysLoggedMonitorTable(ChangeLogEntry, RecRef, FldRef);
        IsMonitoredFieldActive := IsMonitoredField(TempChangeLogSetupField, RecRef, FldRef, IsMonitorEnabled);

        if IsAlwaysLoggedMonitorTableActive or IsMonitoredFieldActive then begin
            if not IsAlwaysLoggedMonitorTableActive then
                ChangeLogEntry."Field Log Entry Feature" := ChangeLogEntry."Field Log Entry Feature"::"Monitor Sensitive Fields";

            if IsMonitoredFieldActive then begin
                if TempChangeLogSetupField.Notify then
                    MonitoredFieldNotification.SendEmailNotificationOfSensitiveFieldChange(RecRef, FldRef.Number, ChangeLogEntry."Old Value", ChangeLogEntry."New Value", MonitorFieldNotification)
                else
                    MonitorFieldNotification := MonitorFieldNotification::"Turned Off";
                ChangeLogEntry."Notification Status" := MonitorFieldNotification;
            end;

            Attributes.Add('tableCaption', RecRef.Caption);
            Attributes.Add('fieldCaption', FldRef.Caption);
            Session.LogMessage('0000CTE', StrSubstNo(SensitiveFieldValueHasChangedTxt, FldRef.Caption, RecRef.Caption), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Attributes);
            IncrementNotification(RecRef);
        end;
    end;

    procedure IsIgnoredMonitorField(Recref: RecordRef; FldRef: FieldRef): Boolean
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        ChangeLogSetupField: Record "Change Log Setup (Field)";
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        case Recref.Number of
            Database::"Field Monitoring Setup":
                exit(FldRef.Number = FieldMonitoringSetup.FieldNo("Notification Count"));
            Database::"Change Log Setup (Field)":
                if RecRef.Field(ChangeLogSetupTable.FieldNo("Monitor Sensitive Field")).Value then
                    exit((FldRef.Number <> ChangeLogSetupField.FieldNo("Table No.")) and
                        (FldRef.Number <> ChangeLogSetupField.FieldNo("Field No.")) and
                        (FldRef.Number <> ChangeLogSetupField.FieldNo(Notify)));
            Database::"Change Log Setup (Table)":
                exit(RecRef.Field(ChangeLogSetupTable.FieldNo("Monitor Sensitive Field")).Value);
        end;
    end;

    procedure OpenChangedRecordPage(TableNo: Integer; FieldNo: Integer; RecordSystemID: Guid)
    var
        PageManagement: Codeunit "Page Management";
        RecRef: RecordRef;
    begin
        if TableNo = Database::"Change Log Entry" then
            exit;

        RecRef.Open(TableNo);
        if RecRef.IsTemporary or IsNullGuid(RecordSystemID) then
            exit;

        if not RecRef.GetBySystemId(RecordSystemID) then begin
            Message(NoAvailablePageMsg);
            Error('');
        end;

        if not PageManagement.PageRunAtField(RecRef, FieldNo, false) then begin
            Message(NoAvailablePageMsg);
            Error('');
        end;
    end;

    procedure ResetNotificationCount()
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
    begin
        if FieldMonitoringSetup.Get() then begin
            FieldMonitoringSetup."Notification Count" := 0;
            FieldMonitoringSetup.Modify();
        end;
    end;

    local procedure IsAlwaysLoggedMonitorTable(var ChangeLogEntry: Record "Change Log Entry"; RecRef: RecordRef; FldRef: FieldRef): Boolean
    var
        User: Record User;
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        ChangeLogSetupField: Record "Change Log Setup (Field)";
        MonitorFieldNotification: Enum "Monitor Field Notification";
    begin
        case RecRef.Number of
            Database::User:
                if FldRef.Number = User.FieldNo("Contact Email") then
                    ChangeLogEntry."Field Log Entry Feature" := ChangeLogEntry."Field Log Entry Feature"::All;

            Database::"Change Log Setup (Field)":
                if RecRef.Field(ChangeLogSetupField.FieldNo("Monitor Sensitive Field")).Value then
                    ChangeLogEntry."Field Log Entry Feature" := ChangeLogEntry."Field Log Entry Feature"::"Monitor Sensitive Fields";

            Database::"Field Monitoring Setup":
                begin
                    ChangeLogEntry."Field Log Entry Feature" := ChangeLogEntry."Field Log Entry Feature"::"Monitor Sensitive Fields";
                    if FldRef.Number in [FieldMonitoringSetup.FieldNo("User Id"), FieldMonitoringSetup.FieldNo("Monitor Status")] then begin
                        MonitoredFieldNotification.SendEmailNotificationOfSensitiveFieldChange(RecRef, FldRef.Number, ChangeLogEntry."Old Value", ChangeLogEntry."New Value", MonitorFieldNotification);
                        ChangeLogEntry."Notification Status" := MonitorFieldNotification;
                    end;
                end;
        end;
        exit(ChangeLogEntry."Field Log Entry Feature" in [ChangeLogEntry."Field Log Entry Feature"::All, ChangeLogEntry."Field Log Entry Feature"::"Monitor Sensitive Fields"]);
    end;

    local procedure IsMonitoredField(var TempChangeLogSetupField: Record "Change Log Setup (Field)" temporary; Recref: RecordRef; FldRef: FieldRef; IsMonitorEnabled: Boolean): Boolean
    var
        MonitorSensitiveField: Codeunit "Monitor Sensitive Field";
    begin
        if IsMonitorEnabled then
            if TempChangeLogSetupField.Get(RecRef.Number, FldRef.Number) then
                if MonitorSensitiveField.IsValidTable(Recref.Number) then
                    exit(TempChangeLogSetupField."Monitor Sensitive Field");
    end;

    local procedure IncrementNotification(RecRef: RecordRef)
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        NotificationCount: Integer;
    begin
        if RecRef.Number = Database::"Field Monitoring Setup" then begin
            NotificationCount := RecRef.Field(FieldMonitoringSetup.FieldNo("Notification Count")).Value();
            RecRef.Field(FieldMonitoringSetup.FieldNo("Notification Count")).Value(NotificationCount + 1);
        end else
            if FieldMonitoringSetup.Get() then begin
                FieldMonitoringSetup."Notification Count" += 1;
                FieldMonitoringSetup.Modify();
            end;
    end;

    var
        MonitoredFieldNotification: Codeunit "Monitored Field Notification";
        NoAvailablePageMsg: Label 'There is not a page to open for this entry';
        SensitiveFieldValueHasChangedTxt: Label 'Sensitive field value has changed: %1 in table %2 ', Locked = true;
}