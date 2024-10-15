codeunit 132806 "Upgrade Monitor Field Setup"
{
    Subtype = Upgrade;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerCompany', '', false, false)]
    local procedure SetupMonitorSensistiveField()
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        ChangeLogEntry: Record "Change Log Entry";
    begin
        if not FieldMonitoringSetup.get() then
            FieldMonitoringSetup.Insert();

        FieldMonitoringSetup."Notification Count" := 1;
        FieldMonitoringSetup.Modify();

        InsertMonitorSensitiveFieldEntry(true);
        InsertMonitorSensitiveFieldEntry(false);
    end;


    local procedure InsertMonitorSensitiveFieldEntry(MonitorFeature: Boolean)
    var
        ChangeLogEntry: Record "Change Log Entry";
    begin
        if MonitorFeature then
            ChangeLogEntry."Field Log Entry Feature" := ChangeLogEntry."Field Log Entry Feature"::"Monitor Sensitive Fields"
        else
            ChangeLogEntry."Field Log Entry Feature" := ChangeLogEntry."Field Log Entry Feature"::All;
        ChangeLogEntry."Table No." := Database::"Field Monitoring Setup";
        ChangeLogEntry."Field No." := 1;
        ChangeLogEntry.Insert();
    end;
}